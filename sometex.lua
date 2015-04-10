#!/usr/bin/env texlua

-- display usage message

function show_usage()
  local usage = [[
>>>>>>>>>> sometex v0.1 from https://github.com/zohooo/sometex <<<<<<<<<<
Usage:
  [Linux]    sometex.lua [options] texfile
  [Windows]  sometex.bat [options] texfile
Options:
  -f fragment    the fragment to be compiled, e.g., chapter, section, block
  -l line        current line number, e.g., 210
  -p program     the program for compiling, e.g., xelatex, pdflatex
  -s switch      switch options to be passed to the program
Example:
  sometex.bat -f section -l 210 -p xelatex -s "-synctex=-1 -quiet" mytex
]]
  io.write("\n" .. usage)
end

-- parse the arguments

local devel, fragment, line, program, switch, name
local tempname

function parse_args()
  local i, v = 1, arg[1]
  if (not v or v == "-h") then show_usage(); os.exit() end
  while v do
    if v == "-d" then
      devel = true
    else if v == "-f" then
      i = i + 1
      fragment = arg[i]
    else if v == "-l" then
      i = i + 1
      line = tonumber(arg[i])
    else if v == "-p" then
      i = i + 1
      program = arg[i]
    else if v == "-s" then
      i = i + 1
      switch = string.gsub(arg[i], "synctex=1", "synctex=-1")
    else
      if v ~= "" then
        name = v
        if string.sub(name, -4) == ".tex" then name = string.sub(name, 0, -5) end
      end
    end end end end end
    i = i + 1; v = arg[i]
  end
  tempname = name .. ".tmp"
  if devel then
    print("Arguments: " .. arg[-1] .. " " .. arg[0] .. " " .. arg[1] .. " " .. arg[2]);
    print(fragment, line, program, switch, name)
  end
end

-- read the content of tex file

local texlines = {}

function read_lines()
  local file = io.input(name .. ".tex")
  for l in io.lines() do
    table.insert(texlines, l)
  end
  io.close(file)
end

-- read magic comments at the beginning of tex file

function read_comments()
  for i = 1, math.min(table.getn(texlines), 30) do
    local l = texlines[i]
    _, _, k, v = string.find(l, "!T[Ee]X%s*(%a+)%s*=%s*(%a+)")
    if k and v then
      if devel then print(k, v) end
      if not program and k == "program" then
        program = v
      else if not fragment and k == "fragment" then
        fragment = v
      end end
    end
  end
  if devel then print(fragment, line, program, switch, name) end
  if not program then
    program = "xelatex"
    print("Warning: missing '-p program' option, default to '-p xelatex'.")
  end
  if not fragment then
    print("Error: missing '-f fragment' option!")
    os.exit()
  end
end

-- locate the lines need to be compiled

local pline, bline, eline = 0, 0, 0

function locate_lines()
  if (fragment == "block") then
    for i, l in ipairs(texlines) do
      if l == "\\begin{document}" then pline = i end
      if l == "" then
        if i <= line then bline = i else eline = i; break end
      end
    end
  else
    local sectioning = {
      part = 1, chapter = 2, section = 3, subsection = 4,
      subsubsection = 5, paragraph = 6, subparagraph = 7
    }
    local level = sectioning[fragment]
    if not level then
      print("Error: invalid fragment '" .. fragment .. "'!")
      os.exit()
    end
    for i, l in ipairs(texlines) do
      if l == "\\begin{document}" then pline = i end
      _, _, s = string.find(l,"^\\(%a+)%*?[%[{]")
      local level0 = sectioning[s]
      if level0 and level0 <= level then
        if devel then print(i, l) end
        if i <= line then bline = i else eline = i - 1; break end
      end
    end
  end
  if devel then print("bline", bline, "eline", eline) end
end

-- write the fragment to temp file

function write_lines()
  local file = io.output(tempname)
  for i = 1, pline do
    io.write(texlines[i], "\n");
  end
  io.write(string.rep("\n", bline - pline - 1))
  for i = bline, eline do
    io.write(texlines[i], "\n");
  end
  io.write(string.rep("\n",  table.getn(texlines) - eline - 1))
  io.write("\\end{document}", "\n");
  io.close(file)
end

-- execute latex compiler

function execute_tex()
  local c = program .. " " .. switch .. " " .. tempname
  if devel then print(c) end
  os.execute(c)
end

-- modify synctex file

function modify_synctex()
  local file = io.input(name .. ".synctex")
  local text = io.read("*all")
  text = string.gsub(text, "%.tmp", ".tex")
  io.close(file)
  file = io.output(name .. ".synctex")
  io.write(text)
  io.close(file)
end

-- main function

function main()
  parse_args()
  read_lines()
  read_comments()
  locate_lines()
  write_lines()
  execute_tex()
  modify_synctex()
end

main()
