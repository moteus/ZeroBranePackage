-- Test suite for snippets.lua
local SnippetManager = package_require 'snippets.manager'
local Editor         = package_require 'snippets.editor'

-- TODO
-- snippets.scivar = "$(FilePath)"
local manager = SnippetManager:new()

local function print(...)
  ide:Print(...)
end

local function test_snippets(editor)
  manager:load_config {
    {activation = "tabs",     text = "${3:three} ${1:one} ${2:two}"               },
    {activation = "etabs",    text = "${2:one ${1:two} ${3:three}} ${4:four}"     },
    {activation = "mirrors",  text = "${1:one} ${2:two} ${1} ${2}"                },
    {activation = "rmirrors", text = "${1:one} ${1/one/two/}"                     },
    {activation = "rgroups",  text = [[Ordered pair: ${1:(2, 8)} so ${1/(\d), (\d)/x = $1, y = $2/}]]},
    {activation = "trans",    text = "${1:one} ${1/o(ne)?/O$1/}"                  },
    {activation = "esc",      text = [[\${1:fake one} ${1:real one} {${2:\} two}]]},
    {activation = "eruby",    text = "${1:one} ${1/.+/#{$0.capitalize}/}"         },
  }
  manager:release(editor)

  local eol = Editor.GetEOL(editor)

  do -- Tab stops
    editor:ClearAll()
    print('testing tab stops')
    editor:AddText("tabs"); manager:insert(editor)
    assert( Editor.GetSelText(editor) == "one" )
    assert( editor:GetText(editor) == "${3:three} one ${2:two}" .. eol )
    editor:ReplaceSelection('foo')

    manager:next(editor)
    assert( Editor.GetSelText(editor) == "two" )
    assert( editor:GetText(editor) == "${3:three} foo two" .. eol )

    manager:prev(editor)
    assert( Editor.GetSelText(editor) == "one" )
    assert( editor:GetText(editor) == "${3:three} one ${2:two}" .. eol )

    manager:next(editor)
    assert( Editor.GetSelText(editor) == "two" )
    assert( editor:GetText(editor) == "${3:three} one two" .. eol )

    manager:next(editor)
    assert( Editor.GetSelText(editor) == "three" )
    manager:next(editor)
    assert( editor:GetText() == "three one two" )
    print('tab stops passed')
  end

  do -- Embedded tab stops
    editor:ClearAll()
    print('testing embedded tab stops')
    editor:AddText('etabs'); manager:insert(editor)
    assert( Editor.GetSelText(editor) == 'two')
    manager:next(editor)
    assert( Editor.GetSelText(editor) == 'one two ${3:three}' )
    manager:next(editor)
    assert(Editor.GetSelText(editor) == 'three')
    manager:next(editor)
    manager:next(editor)
    assert( editor:GetText() == 'one two three four' )
    print('embedded tabs passed')
  end

  do -- Mirrors
    editor:ClearAll()
    print('testing mirrors')
    editor:AddText('mirrors'); manager:insert(editor)
    manager:next(editor)
    assert( editor:GetText() == 'one two one ${2}' .. eol )

    manager:prev(editor)
    assert( editor:GetText() == 'one ${2:two} ${1} ${2}' .. eol )
    assert( Editor.GetSelText(editor) == 'one' )

    manager:next(editor)
    assert( editor:GetText() == 'one two one ${2}' .. eol )

    editor:DeleteBack(); editor:AddText('three')
    manager:next(editor)
    assert( editor:GetText() == 'one three one three' )
    print('mirrors passed')
	end

  do -- Regex Mirrors
    editor:ClearAll()
    print('testing regex mirrors')
    editor:AddText('rmirrors'); manager:insert(editor)
    manager:next(editor)
    assert( editor:GetText() == 'one two' )
    editor:ClearAll()
    editor:AddText('rmirrors'); manager:insert(editor)
    editor:DeleteBack(); editor:AddText('two')
    manager:next(editor)
    assert( editor:GetText() == 'two ' )
    print('regex mirrors passed')
  end

  do -- Regex Groups
    editor:ClearAll()
    print('testing regex groups')
    editor:AddText('rgroups'); manager:insert(editor)
    manager:next(editor)
    assert( editor:GetText() == 'Ordered pair: (2, 8) so x = 2, y = 8' )
    editor:ClearAll()
    editor:AddText('rgroups'); manager:insert(editor)
    editor:DeleteBack(); editor:AddText('[5, 9]')
    manager:next(editor)
    assert( editor:GetText() == 'Ordered pair: [5, 9] so x = 5, y = 9' )
    print('regex groups passed')
  end

  do -- Transformations
    editor:ClearAll()
    print('testing transformations')
    editor:AddText('trans'); manager:insert(editor)
    manager:next(editor)
    assert( editor:GetText() == 'one One' )
    editor:ClearAll()
    editor:AddText('trans'); manager:insert(editor)
    editor:DeleteBack(); editor:AddText('once')
    manager:next(editor)
    assert( editor:GetText() == 'once O' )
    print('transformations passed')
  end

  if false then -- SciTE variables
    editor:ClearAll()
    print('testing scite variables')
    editor:AddText('scivar'); manager:insert(editor)
    assert( editor:GetText() == props['FilePath'] )
    print('scite variables passed')
  end

  do -- Escapes
    editor:ClearAll()
    print('testing escapes')
    editor:AddText('esc'); manager:insert(editor)
    assert( Editor.GetSelText(editor) == 'real one' )
    manager:next(editor)
    assert( Editor.GetSelText(editor) == '\\} two' )
    manager:next(editor)
    assert( editor:GetText() == '${1:fake one} real one {} two' )
    print('escapes passed')
  end

  do -- Embeded Ruby
    editor:ClearAll()
    print('testing embedded ruby')
    editor:AddText('eruby'); manager:insert(editor)
    manager:next(editor)
    assert( editor:GetText() == 'one One' )
    editor:ClearAll()
    editor:AddText('eruby'); manager:insert(editor)
    editor:DeleteBack(); editor:AddText('two')
    manager:next(editor)
    assert( editor:GetText() == 'two Two' )
    print('embedded ruby passed')
  end
end

local function test_cancel(editor)
  manager:load_config{
    {
      activation = {'key', 'Ctrl+1'},
      text = '$(SelectedText)${1:}'
    },
    {
      activation = {'tab', '111222'},
      text = '$(SelectedText)${1:}'
    }
  }
  manager:release(editor)

  local eol = Editor.GetEOL(editor)

  if true then -- cancel key
    editor:ClearAll()
    print('testing cancel snippet with key activation')
    editor:AddText("111222333")

    editor:SetAnchor(3) editor:SetCurrentPos(6)
    manager:insert(editor, 'Ctrl+I') -- Do not change selection for unknown snippet
    assert( Editor.GetSelText(editor) == "222" )
    assert( editor:GetCurrentPos() == 6 )

    editor:SetAnchor(6) editor:SetCurrentPos(3)
    manager:insert(editor, 'Ctrl+I') -- Do not change selection for unknown snippet
    assert( Editor.GetSelText(editor) == "222" )
    assert( editor:GetCurrentPos() == 3 )

    manager:insert(editor, 'Ctrl+1')
    assert( editor:GetText() == '111222' .. eol .. '333' )
    assert( editor:GetCurrentPos() == 6 )
    assert( Editor.GetSelText(editor) == "" )
    editor:AddText('444')

    manager:cancel(editor)
    assert( editor:GetText() == '111222333' )
    assert( Editor.GetSelText(editor) == "222" )
    assert( editor:GetCurrentPos() == 6 ) -- TODO restore correct position
    print('testing cancel snippet with key activation passed')
  end

  if true then -- cancel tab
    editor:ClearAll()
    print('testing cancel snippet with key activation')
    editor:AddText("111222333")

    editor:SetAnchor(3) editor:SetCurrentPos(5)
    manager:insert(editor)
    assert( Editor.GetSelText(editor) == "22" )
    assert( editor:GetCurrentPos() == 5 )

    editor:SetAnchor(5) editor:SetCurrentPos(3)
    manager:insert(editor, 'Ctrl+I') -- Do not change selection for unknown snippet
    assert( Editor.GetSelText(editor) == "22" )
    assert( editor:GetCurrentPos() == 3 )

    editor:SetSelection(6, 6);
    manager:insert(editor)
    assert( editor:GetText() == '' .. eol .. '333' )
    assert( editor:GetCurrentPos() == 0 )
    assert( Editor.GetSelText(editor) == "" )
    editor:AddText('444')

    manager:cancel(editor)
    assert( editor:GetText() == '111222333' )
    assert( editor:GetCurrentPos() == 6 ) -- TODO restore correct position

    if false then
      -- TODO not supported correctly cancel for tab activatin with selection
      editor:SetAnchor(3) editor:SetCurrentPos(6)
      manager:insert(editor)
      assert( editor:GetText() == '222' .. eol .. '333' )
      assert( editor:GetCurrentPos() == 3 )
      assert( Editor.GetSelText(editor) == "" )
      editor:AddText('444')

      manager:cancel(editor)
      assert( editor:GetText() == '111222333' )
      assert( editor:GetCurrentPos() == 6 ) -- TODO restore correct position
    end

    print('testing cancel snippet with key activation passed')
  end
end

local function run()
  local editor = NewFile()
  test_snippets(editor)
  test_cancel(editor)
  ide:GetDocument(editor):SetModified(false)
  ClosePage()
  print('snippet tests passed')
end

return run