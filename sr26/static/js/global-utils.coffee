window.global = window.global or {}

global.hashCode = (str) ->
  hash = 0
  for i in [0..str.length - 1]
     hash = str.charCodeAt(i) + ((hash << 5) - hash)
  return hash

global.intToARGB = (i) ->
  a = ((i >> 24) & 0xFF).toString(16)
  b = ((i >> 16) & 0xFF).toString(16)
  c = ((i >> 8) & 0xFF).toString(16)
  d = (i & 0xFF).toString(16)
  ret = a + b + c + d
  while ret.length < 6
    ret += "0"
  return ret

global.stringToColor = (s) ->
  "#" + global.intToARGB(global.hashCode s).slice(0, 6)

componentToHex = (c) ->
  c = parseInt c
  hex = c.toString 16
  # return hex.length == 1 ? "0" + hex : hex;
  if hex.length is 1
    return "0" + hex
  else
    return hex

global.rgbToHex  = (r, g, b) ->
  "#" + componentToHex(r) + componentToHex(g) + componentToHex(b);

global.hexToRgb = (hex) ->
  # Expand shorthand form (e.g. "03F") to full form (e.g. "0033FF")
  shorthandRegex = /^#?([a-f\d])([a-f\d])([a-f\d])$/i
  hex = hex.replace shorthandRegex, (m, r, g, b) ->
      r + r + g + g + b + b

  result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec hex
  if result
    return {
      r: parseInt(result[1], 16),
      g: parseInt(result[2], 16),
      b: parseInt(result[3], 16)
    }
  else
    return null

global.pastelize = (color_string) ->
  # takes string like #888888 and returns the mix with #ffffff
  rgb = global.hexToRgb(color_string)
  r = (rgb.r + 255 * 2) / 3
  g = (rgb.g + 255 * 2) / 3
  b = (rgb.b + 255 * 2) / 3
  return global.rgbToHex r, g, b

#### window width/height
global.get_width = () ->
  if self.innerHeight?
    return self.innerWidth

###
          else if (document.documentElement && document.documentElement.clientHeight)
          {
                  x = document.documentElement.clientWidth;
          }
          else if (document.body)
          {
                  x = document.body.clientWidth;
          }
          return x;
  }

  function GetHeight()
  {
          var y = 0;
          if (self.innerHeight)
          {
                  y = self.innerHeight;
          }
          else if (document.documentElement && document.documentElement.clientHeight)
          {
                  y = document.documentElement.clientHeight;
          }
          else if (document.body)
          {
                  y = document.body.clientHeight;
          }
          return y;
  }
###



#### prototype -- bring IE up to date only

if not Array.prototype.indexOf?
  Array.prototype.indexOf = (needle) ->
    for i in [0..this.length - 1]
      if this[i] is needle
        return i
    return -1


global.add_reduce_f = (memo, num) -> memo + num

