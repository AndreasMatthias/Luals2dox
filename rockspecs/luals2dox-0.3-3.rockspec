---@diagnostic disable: lowercase-global

rockspec_format = '3.0'

package = 'luals2dox'
version = '0.3-3'
source = {
   url = 'git+https://github.com/AndreasMatthias/Luals2dox.git',
   tag = 'v0.3-3'
}

description = {
   summary = 'Doxygen filter for Lua files.',
   detailed = [[
      Luals2dox is an input filter for Doxygen that filters Lua files.
      Lua files shall be annotated for use with LuaLS, the Lua Language Server,
      that is a necessary requirement for Luals2dox.
   ]],
   labels ={'doxygen', 'documentation'},
   homepage = 'https://github.com/AndreasMatthias/Luals2dox',
   license = 'GPLv3'
}

dependencies = {
   'lua >= 5.3',
   'lpeg',
   'argparse',
   'lua-cjson',
   'penlight',
   'f-strings',
}

build = {
   type = 'builtin',
   modules = {
      ['luals2dox.init'] = 'src/luals2dox/init.lua',
      ['luals2dox.core'] = 'src/luals2dox/core.lua',
      ['luals2dox.args'] = 'src/luals2dox/args.lua',
   },
   install = {
      bin = {
         ['luals2dox'] = 'src/l2d.lua'
      }
   },
}
