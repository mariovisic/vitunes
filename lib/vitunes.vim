" Vim script that add ability to search and play iTunes tracks from Vim
" Maintainer:	Daniel Choi <dhchoi@gmail.com>
" License: MIT License (c) 2011 Daniel Choi
"
" uncomment for production
" let s:vitunes_tool = 'vitunes'
" development build of command line tool
"let s:vitunes_tool = '/Users/choi/projects/vitunes/build/Release/vitunes '
let s:vitunes_tool = '/Users/choi/projects/vitunes/bin/vitunes-tool '

let s:searchPrompt = "Search iTunes Music Library: "
let s:getPlaylistsCommand = s:vitunes_tool . "playlists"
let s:selectPlaylistPrompt = "Select playlist: "
let s:getArtistsCommand = s:vitunes_tool . "group artist | uniq "
let s:selectArtistPrompt = "Select artist: "
let s:getGenresCommand = s:vitunes_tool . "group genre | uniq "
let s:selectGenrePrompt = "Select genre: "
let s:getAlbumsCommand = s:vitunes_tool . "group album | uniq "
let s:selectAlbumPrompt = "Select album: "
let s:addTracksToPlaylistPrompt = "Add track(s) to this playlist: "

let s:currentPlaylist = ''
let s:lastPlaylist = ''
let s:selectedTrackIds = []

func! s:trimString(string)
  let string = substitute(a:string, '\s\+$', '', '')
  return substitute(string, '^\s\+', '', '')
endfunc

function! s:collectTrackIds(startline, endline)
  let trackIds = []
  let lnum = a:startline
  while lnum <= a:endline
    let trackId = matchstr(getline(lnum), '\d\+$')
    call add(trackIds, trackId)
    let lnum += 1
  endwhile
  return trackIds
endfunc

function! s:runCommand(command)
  " echom a:command " can use for debugging
  let res = system(a:command)
  return res
endfunction

function! ViTunesStatusLine()
  return "%<%f\ Press ? for help. "."%r%=%-14.(%l,%c%V%)\ %P"
endfunction

" the main window
function! ViTunes()
  leftabove split ViTunesBuffer
  setlocal cursorline
  setlocal nowrap
  setlocal textwidth=0
  setlocal buftype=nofile
  setlocal bufhidden=hide
  setlocal noswapfile
  noremap <buffer> ,s :call <SID>openQueryWindow()<cr>
  noremap <buffer> ,p :call <SID>openPlaylistDropdown()<cr>
  noremap <buffer> ,a :call <SID>openArtistDropdown()<cr>
  noremap <buffer> ,g :call <SID>openGenreDropdown()<cr>
  noremap <buffer> ,A :call <SID>openAlbumDropdown()<cr>
  noremap <buffer> ,c :call <SID>openAddToPlaylistDropDown()<cr>

  noremap <buffer> > :call <SID>nextTrack()<cr>
  noremap <buffer> < :call <SID>prevTrack()<cr>
  
  noremap <buffer> .  :call <SID>currentTrackAndPlaylist()<cr>

  noremap <buffer> <Space>  :call <SID>itunesControl("playpause")<cr>
  noremap <buffer> -  :call <SID>changeVolume("volumeDown")<cr>
  noremap <buffer> +  :call <SID>changeVolume("volumeUp")<cr>
  noremap <buffer> =  :call <SID>changeVolume("volumeUp")<cr>

  " Not working yet
  " noremap <buffer> <BS> :call <SID>deleteTracksFromPlaylist()<CR> "
  noremap <buffer> ,i :close<CR>
  noremap <buffer> ? :call <SID>help()<CR>
  "noremap <buffer> <cr> <Esc>:call <SID>playTrack()<cr>
  noremap <buffer> <cr> :call <SID>playTrack()<cr>
  setlocal nomodifiable
  setlocal statusline=%!ViTunesStatusLine()
endfunction

function! s:help()
  " TODO show command list
  " call a Ruby executable that comes with the gem
  " This should just display the README
  set modifiable
  silent! 1,$delete
  silent! put ="HELO another line"
  silent! put ="2HELO another line"
  silent! 1delete
  set nomodifiable
endfunction


function! s:itunesControl(command)
  let res = s:runCommand(s:vitunes_tool . "itunes ".a:command)
  echom res
endfunction

function! s:changeVolume(command)
  let res = s:runCommand(s:vitunes_tool.a:command)
  echom res
endfunction

function! s:playTrack()
  let trackID = matchstr(getline(line('.')), '\d\+$')
  if (trackID == '')
    return
  endif
  let command = ""
  if (s:currentPlaylist != '')
    let command = s:vitunes_tool . "playTrackIDFromPlaylist ".trackID.' '.s:currentPlaylist
  else
    let command = s:vitunes_tool . "playTrackID " . trackID
  endif
  " echom command
  call system(command)
  call s:currentTrackAndPlaylist()
endfunc

function! s:hasTrackID(line)
  if a:line > line('$')
    return 0
  end
  let res = matchstr(getline(a:line), '\d\+$')
  if res != ''
    return 1
  else
    return 0
  end
endfunction

" move up or down the visible list of tracks
function! s:nextTrack()
  if s:hasTrackID(line('.') + 1)
    normal j
    call s:playTrack()
    " call s:itunesControl("nextTrack")
  endif
endfunction

function! s:prevTrack()
  if s:hasTrackID(line('.') - 1)
    normal k
    call s:playTrack()
    " call s:itunesControl("previousTrack")
  endif
endfunction

function! s:currentTrackAndPlaylist()
  let res1 = s:runCommand(s:vitunes_tool . "itunes currentTrack")
  let res2 = s:runCommand(s:vitunes_tool . "itunes currentPlaylist")
  echo res1 . '  |  '.res2
endfunction

function! s:openQueryWindow()
  leftabove split SearchTracks
  setlocal textwidth=0
  setlocal buftype=nofile
  setlocal noswapfile
  setlocal modifiable
  resize 1
  inoremap <buffer> <cr> <Esc>:call <SID>submitQueryOrSelection('search')<cr>
  noremap <buffer> <cr> <Esc>:call <SID>submitQueryOrSelection('search')<cr>
  noremap <buffer> q <Esc>:close
  inoremap <buffer> <Esc> <Esc>:close<CR>
  noremap <buffer> <Esc> <Esc>:close<CR>
  let s:selectionPrompt = s:searchPrompt " this makes sure we parse the query correctly
  call setline(1, s:searchPrompt)
  normal $
  call feedkeys("a", "t")
endfunction

function! GenericCompletion(findstart, base)
  if a:findstart
    let prompt = s:selectionPrompt
    let start = len(prompt) 
    return start
  else
    if (a:base == '')
      return s:selectionList
    else
      let res = []
      " find tracks matching a:base
      for m in s:selectionList
        " why doesn't case insensitive flag work?
        if m =~ '\c' . a:base 
          call add(res, m)
        endif
      endfor
      return res
    endif
  endif
endfun

function! s:commonDropDownConfig()
  setlocal textwidth=0
  setlocal completefunc=GenericCompletion
  setlocal buftype=nofile
  setlocal noswapfile
  setlocal modifiable
  resize 1
  noremap <buffer> q <Esc>:close<cr>
  inoremap <buffer> <Esc> <Esc>:close<cr>
  call setline(1, s:selectionPrompt)
  normal $
endfunction


" Drop downs

function! s:openPlaylistDropdown()
  leftabove split ChoosePlaylist
  inoremap <silent> <buffer> <cr> <Esc>:call <SID>submitQueryOrSelection('playlistTracks')<CR> 
  let s:selectionPrompt = s:selectPlaylistPrompt
  call <SID>commonDropDownConfig()
  let s:selectionList = split(system(s:getPlaylistsCommand), '\n')
  if (s:lastPlaylist != '')
    call insert(s:selectionList, s:lastPlaylist);
    call insert(s:selectionList, s:lastPlaylist);
  endif
  call feedkeys("a\<c-x>\<c-u>\<c-p>", 't')
endfunction

function! s:openArtistDropdown()
  leftabove split ChoosePlaylist
  inoremap <silent> <buffer> <cr> <Esc>:call <SID>submitQueryOrSelection('artist')<CR> 
  let s:selectionPrompt = s:selectArtistPrompt
  call <SID>commonDropDownConfig()
  let s:selectionList = split(system(s:getArtistsCommand), '\n')
  call feedkeys("a\<c-x>\<c-u>\<c-p>", 't')
endfunction

function! s:openGenreDropdown()
  leftabove split ChoosePlaylist
  inoremap <silent> <buffer> <cr> <Esc>:call <SID>submitQueryOrSelection('genre')<CR> 
  let s:selectionPrompt = s:selectGenrePrompt
  call <SID>commonDropDownConfig()
  let s:selectionList = split(system(s:getGenresCommand), '\n')
  call feedkeys("a\<c-x>\<c-u>\<c-p>", 't')
endfunction

function! s:openAlbumDropdown()
  leftabove split ChoosePlaylist
  inoremap <silent> <buffer> <cr> <Esc>:call <SID>submitQueryOrSelection('album')<CR> 
  let s:selectionPrompt = s:selectAlbumPrompt
  call <SID>commonDropDownConfig()
  let s:selectionList = split(system(s:getAlbumsCommand), '\n')
  call feedkeys("a\<c-x>\<c-u>\<c-p>", 't')
endfunction

function! s:openAddToPlaylistDropDown() range
  let s:selectedTrackIds = s:collectTrackIds(a:firstline, a:lastline)
  leftabove split ChoosePlaylist
  inoremap <silent> <buffer> <cr> <Esc>:call <SID>submitQueryOrSelection('addTracksToPlaylist')<CR> 
  let s:selectionPrompt = s:addTracksToPlaylistPrompt 
  echom s:selectionPrompt
  call <SID>commonDropDownConfig()
  let s:selectionList = split(system(s:getPlaylistsCommand), '\n')
  if (s:lastPlaylist != '')
    call insert(s:selectionList, s:lastPlaylist);
  endif
  call feedkeys("a\<c-x>\<c-u>\<c-p>", 't')
endfunction

" selection window pick or search window query
function! s:submitQueryOrSelection(command)
  if (getline('.') =~ '^\s*$')
    close
    return
  endif

  let query = getline('.')[len(s:selectionPrompt):] " get(split(getline('.'), ':\s*'), 1)
  close
  " echom query
  if (len(query) == 0 || query =~ '^\s*$')
    return
  endif
  if a:command == 'artist'
    let query = substitute(query, "'", "\'", '')
    let bcommand = s:vitunes_tool."predicate ".shellescape("artist == '".query."'")
  elseif a:command == 'genre'
    let bcommand = s:vitunes_tool."predicate ".shellescape("genre == '".query."'") 
  elseif a:command == 'album'
    let bcommand = s:vitunes_tool."predicate ".shellescape("album == '".query."'") 
  elseif a:command == 'addTracksToPlaylist'
    let trackIds = join(s:selectedTrackIds, ',')
    let bcommand = s:vitunes_tool.a:command." ".trackIds." ".query 
  else
    let bcommand = s:vitunes_tool . a:command . ' ' . shellescape(query)
  end
  echom bcommand
  let res = s:runCommand(bcommand)
  if a:command == 'addTracksToPlaylist'
    let res = system(s:vitunes_tool.'playlistTracks '.shellescape(query))
  endif
  setlocal modifiable
  silent! 1,$delete
  silent! put =res
  silent! 1delete
  setlocal nomodifiable
  " position cursor at 1st track
  normal 3G
  if (a:command == 'playlistTracks')
    let s:currentPlaylist = query
    let s:lastPlaylist = query
  else
    let s:currentPlaylist = ''
  endif
endfunction

" TODO does not work yet
function! s:deleteTracksFromPlaylist() range
  if (s:currentPlaylist == '')
    echom "You can't delete tracks unless you're in a playlist"
    return
  endif
  let s:selectedTrackIds = s:collectTrackIds(a:firstline, a:lastline)
  let trackIds = join(s:selectedTrackIds, ',')
  let bcommand = s:vitunes_tool.'rmTracksFromPlaylist '.trackIds." ".s:currentPlaylist 
  echom bcommand
  let res = system(bcommand)
  " delete lines from buffer
  echom res
endfunction

nnoremap <silent> <leader>i :call ViTunes()<cr>

let g:ViTunesLoaded = 1

