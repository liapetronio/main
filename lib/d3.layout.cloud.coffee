# Word cloud layout by Jason Davies, http://www.jasondavies.com/word-cloud/
# Algorithm due to Jonathan Feinberg, http://static.mrfeinberg.com/bv_ch03.pdf
(->
  cloud = ->
    
    # Temporary hack
    place = (board, tag, bounds) ->
      perimeter = [
        {
          x: 0
          y: 0
        }
        {
          x: size[0]
          y: size[1]
        }
      ]
      startX = tag.x
      startY = tag.y
      maxDelta = Math.sqrt(size[0] * size[0] + size[1] * size[1])
      s = spiral(size)
      dt = (if Math.random() < .5 then 1 else -1)
      t = -dt
      dxdy = undefined
      dx = undefined
      dy = undefined
      while dxdy = s(t += dt)
        dx = ~~dxdy[0]
        dy = ~~dxdy[1]
        break  if Math.min(dx, dy) > maxDelta
        tag.x = startX + dx
        tag.y = startY + dy
        continue  if tag.x + tag.x0 < 0 or tag.y + tag.y0 < 0 or tag.x + tag.x1 > size[0] or tag.y + tag.y1 > size[1]
        
        # TODO only check for collisions within current bounds.
        if not bounds or not cloudCollide(tag, board, size[0])
          if not bounds or collideRects(tag, bounds)
            sprite = tag.sprite
            w = tag.width >> 5
            sw = size[0] >> 5
            lx = tag.x - (w << 4)
            sx = lx & 0x7f
            msx = 32 - sx
            h = tag.y1 - tag.y0
            x = (tag.y + tag.y0) * sw + (lx >> 5)
            last = undefined
            j = 0

            while j < h
              last = 0
              i = 0

              while i <= w
                board[x + i] |= (last << msx) | ((if i < w then (last = sprite[j * w + i]) >>> sx else 0))
                i++
              x += sw
              j++
            delete tag.sprite

            return true
      false
    size = [
      256
      256
    ]
    text = cloudText
    font = cloudFont
    fontSize = cloudFontSize
    fontStyle = cloudFontNormal
    fontWeight = cloudFontNormal
    rotate = cloudRotate
    padding = cloudPadding
    spiral = archimedeanSpiral
    words = []
    timeInterval = Infinity
    event = d3.dispatch("word", "end")
    timer = null
    cloud = {}
    cloud.start = ->
      step = ->
        start = +new Date
        d = undefined
        while +new Date - start < timeInterval and ++i < n and timer
          d = data[i]
          d.x = (size[0] * (Math.random() + .5)) >> 1
          d.y = (size[1] * (Math.random() + .5)) >> 1
          cloudSprite d, data, i
          if d.hasText and place(board, d, bounds)
            tags.push d
            event.word d
            if bounds
              cloudBounds bounds, d
            else
              bounds = [
                {
                  x: d.x + d.x0
                  y: d.y + d.y0
                }
                {
                  x: d.x + d.x1
                  y: d.y + d.y1
                }
              ]
            d.x -= size[0] >> 1
            d.y -= size[1] >> 1
        if i >= n
          cloud.stop()
          event.end tags, bounds
        return
      board = zeroArray((size[0] >> 5) * size[1])
      bounds = null
      n = words.length
      i = -1
      tags = []
      data = words.map((d, i) ->
        d.text = text.call(this, d, i)
        d.font = font.call(this, d, i)
        d.style = fontStyle.call(this, d, i)
        d.weight = fontWeight.call(this, d, i)
        d.rotate = rotate.call(this, d, i)
        d.size = ~~fontSize.call(this, d, i)
        d.padding = padding.call(this, d, i)
        d
      ).sort((a, b) ->
        b.size - a.size
      )
      clearInterval timer  if timer
      timer = setInterval(step, 0)
      step()
      return cloud
      return

    cloud.stop = ->
      if timer
        clearInterval timer
        timer = null
      cloud

    cloud.timeInterval = (x) ->
      return timeInterval  unless arguments.length
      timeInterval = (if not x? then Infinity else x)
      cloud

    cloud.words = (x) ->
      return words  unless arguments.length
      words = x
      cloud

    cloud.size = (x) ->
      return size  unless arguments.length
      size = [
        +x[0]
        +x[1]
      ]
      cloud

    cloud.font = (x) ->
      return font  unless arguments.length
      font = d3.functor(x)
      cloud

    cloud.fontStyle = (x) ->
      return fontStyle  unless arguments.length
      fontStyle = d3.functor(x)
      cloud

    cloud.fontWeight = (x) ->
      return fontWeight  unless arguments.length
      fontWeight = d3.functor(x)
      cloud

    cloud.rotate = (x) ->
      return rotate  unless arguments.length
      rotate = d3.functor(x)
      cloud

    cloud.text = (x) ->
      return text  unless arguments.length
      text = d3.functor(x)
      cloud

    cloud.spiral = (x) ->
      return spiral  unless arguments.length
      spiral = spirals[x + ""] or x
      cloud

    cloud.fontSize = (x) ->
      return fontSize  unless arguments.length
      fontSize = d3.functor(x)
      cloud

    cloud.padding = (x) ->
      return padding  unless arguments.length
      padding = d3.functor(x)
      cloud

    d3.rebind cloud, event, "on"
  cloudText = (d) ->
    d.text
  cloudFont = ->
    "serif"
  cloudFontNormal = ->
    "normal"
  cloudFontSize = (d) ->
    Math.sqrt d.value
  cloudRotate = ->
    (~~(Math.random() * 6) - 3) * 30
  cloudPadding = ->
    1
  
  # Fetches a monochrome sprite bitmap for the specified text.
  # Load in batches for speed.
  cloudSprite = (d, data, di) ->
    return  if d.sprite
    c.clearRect 0, 0, (cw << 5) / ratio, ch / ratio
    x = 0
    y = 0
    maxh = 0
    n = data.length
    --di
    while ++di < n
      d = data[di]
      c.save()
      c.font = d.style + " " + d.weight + " " + ~~((d.size + 1) / ratio) + "px " + d.font
      w = c.measureText(d.text + "m").width * ratio
      h = d.size << 1
      if d.rotate
        sr = Math.sin(d.rotate * cloudRadians)
        cr = Math.cos(d.rotate * cloudRadians)
        wcr = w * cr
        wsr = w * sr
        hcr = h * cr
        hsr = h * sr
        w = (Math.max(Math.abs(wcr + hsr), Math.abs(wcr - hsr)) + 0x1f) >> 5 << 5
        h = ~~Math.max(Math.abs(wsr + hcr), Math.abs(wsr - hcr))
      else
        w = (w + 0x1f) >> 5 << 5
      maxh = h  if h > maxh
      if x + w >= (cw << 5)
        x = 0
        y += maxh
        maxh = 0
      break  if y + h >= ch
      c.translate (x + (w >> 1)) / ratio, (y + (h >> 1)) / ratio
      c.rotate d.rotate * cloudRadians  if d.rotate
      c.fillText d.text, 0, 0
      if d.padding
        c.lineWidth = 2 * d.padding
        c.strokeText(d.text, 0, 0)
      c.restore()
      d.width = w
      d.height = h
      d.xoff = x
      d.yoff = y
      d.x1 = w >> 1
      d.y1 = h >> 1
      d.x0 = -d.x1
      d.y0 = -d.y1
      d.hasText = true
      x += w
    pixels = c.getImageData(0, 0, (cw << 5) / ratio, ch / ratio).data
    sprite = []
    while --di >= 0
      d = data[di]
      continue  unless d.hasText
      w = d.width
      w32 = w >> 5
      h = d.y1 - d.y0
      
      # Zero the buffer
      i = 0

      while i < h * w32
        sprite[i] = 0
        i++
      x = d.xoff
      return  unless x?
      y = d.yoff
      seen = 0
      seenRow = -1
      j = 0

      while j < h
        i = 0

        while i < w
          k = w32 * j + (i >> 5)
          m = (if pixels[((y + j) * (cw << 5) + (x + i)) << 2] then 1 << (31 - (i % 32)) else 0)
          sprite[k] |= m
          seen |= m
          i++
        if seen
          seenRow = j
        else
          d.y0++
          h--
          j--
          y++
        j++
      d.y1 = d.y0 + seenRow
      d.sprite = sprite.slice(0, (d.y1 - d.y0) * w32)
    return
  
  # Use mask-based collision detection.
  cloudCollide = (tag, board, sw) ->
    sw >>= 5
    sprite = tag.sprite
    w = tag.width >> 5
    lx = tag.x - (w << 4)
    sx = lx & 0x7f
    msx = 32 - sx
    h = tag.y1 - tag.y0
    x = (tag.y + tag.y0) * sw + (lx >> 5)
    last = undefined
    j = 0

    while j < h
      last = 0
      i = 0

      while i <= w
        return true  if ((last << msx) | ((if i < w then (last = sprite[j * w + i]) >>> sx else 0))) & board[x + i]
        i++
      x += sw
      j++
    false
  cloudBounds = (bounds, d) ->
    b0 = bounds[0]
    b1 = bounds[1]
    b0.x = d.x + d.x0  if d.x + d.x0 < b0.x
    b0.y = d.y + d.y0  if d.y + d.y0 < b0.y
    b1.x = d.x + d.x1  if d.x + d.x1 > b1.x
    b1.y = d.y + d.y1  if d.y + d.y1 > b1.y
    return
  collideRects = (a, b) ->
    a.x + a.x1 > b[0].x and a.x + a.x0 < b[1].x and a.y + a.y1 > b[0].y and a.y + a.y0 < b[1].y
  archimedeanSpiral = (size) ->
    e = size[0] / size[1]
    (t) ->
      [
        e * (t *= .1) * Math.cos(t)
        t * Math.sin(t)
      ]
  rectangularSpiral = (size) ->
    dy = 4
    dx = dy * size[0] / size[1]
    x = 0
    y = 0
    (t) ->
      sign = (if t < 0 then -1 else 1)
      
      # See triangular numbers: T_n = n * (n + 1) / 2.
      switch (Math.sqrt(1 + 4 * sign * t) - sign) & 3
        when 0
          x += dx
        when 1
          y += dy
        when 2
          x -= dx
        else
          y -= dy
      [
        x
        y
      ]
  
  # TODO reuse arrays?
  zeroArray = (n) ->
    a = []
    i = -1
    a[i] = 0  while ++i < n
    a
  cloudRadians = Math.PI / 180
  cw = 1 << 11 >> 5
  ch = 1 << 11
  canvas = undefined
  ratio = 1
  if typeof document isnt "undefined"
    canvas = document.createElement("canvas")
    canvas.width = 1
    canvas.height = 1
    ratio = Math.sqrt(canvas.getContext("2d").getImageData(0, 0, 1, 1).data.length >> 2)
    canvas.width = (cw << 5) / ratio
    canvas.height = ch / ratio
  else
    
    # Attempt to use node-canvas.
    canvas = new Canvas(cw << 5, ch)
  c = canvas.getContext("2d")
  spirals =
    archimedean: archimedeanSpiral
    rectangular: rectangularSpiral

  c.fillStyle = c.strokeStyle = "red"
  c.textAlign = "center"
  if typeof module is "object" and module.exports
    module.exports = cloud
  else
    (d3.layout or (d3.layout = {})).cloud = cloud
  return
)()