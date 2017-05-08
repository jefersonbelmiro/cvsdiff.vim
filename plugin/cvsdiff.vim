" vim plugin for cvs diff
" description:
"   vim plugin to use vim split diff on cvs

scriptencoding iso-8859-1

" ligar debug
let s:lDebug = 0

" arquivo do debug
let s:sDebugFile = '/tmp/debugcvs'

" Objeto com versoes a serem comparadas
let s:oVersoes = {}
let s:oVersoes.primeiraVersao  = ''
let s:oVersoes.primeiraSelecao = ''
let s:oVersoes.segundaVersao   = ''
let s:oVersoes.segundaSelecao  = ''

" Caminho absoluto para arquivo atual
let s:path = resolve(expand('<sfile>:p:h')) . '/cvsdiff'

let s:sNome = "CVS\ DIFF\ "
"
" Gera log da execucao do script
"
function! s:LogDebugMessage(msg) abort

  if s:lDebug

    execute 'redir >> ' . s:sDebugFile
    silent echon strftime('%H:%M:%S') . ': ' . a:msg . "\n"
    redir END

  endif

endfunction

function! GenerateStatusline() abort
  return 'CVS DIFF ' . s:sArquivo
endfunction

function! s:CriarJanela() abort

  let s:sNome = "CVS\ DIFF\ " . expand('%:t') . " "

  exe "silent keepalt botright split " . expand('%:t') . "[cvsdiff]"
  "exe "silent keepalt botright split [cvsdiff]"

  exe ':%d'
  silent read /tmp/cvslogvim
  exe ':0d'

  exe 'resize 10'

  if line('$') < 10
    exe 'resize ' . line('$')
  endif

  setlocal filetype=cvsdiff
  setlocal buftype=nofile
	setlocal bufhidden=delete
  setlocal nobackup
  setlocal noswapfile
  setlocal nobuflisted
  setlocal nolist
  setlocal cursorline
  setlocal nonumber
  setlocal nowrap
  setlocal winfixwidth
  setlocal textwidth=0
  setlocal nospell
  setlocal nofoldenable
  setlocal foldcolumn=0
  setlocal foldmethod&
  setlocal foldexpr&

  setlocal statusline=%!GenerateStatusline()
  call s:ChangeFileName(s:sNome)

endfunction

function! s:ChangeFileName(sNome)
  silent! bd! a:sNome
	silent! file! `=a:sNome`
endfunction

function! s:MapKeys() abort

  nnoremap <script> <silent> <buffer> <CR> :call Processar()<CR>
  nnoremap <script> <silent> <buffer> m    :call Selecionar()<CR>
  nnoremap <script> <silent> <buffer> q    :call CloseWindow()<CR>
  au WinLeave <buffer> :call CloseWindow()

endfunction

function! Cvsdiff(argumentos)

  call CloseWindow()

  try

    call s:LimparVersoes()

    if !empty( a:argumentos )

      let s:aArgumentos = split(a:argumentos, ' ')

      for sArgumento in s:aArgumentos

        if empty(sArgumento)
          continue
        endif

        if empty(s:oVersoes.primeiraVersao)
          let s:oVersoes.primeiraVersao = sArgumento
          continue
        endif

        if empty(s:oVersoes.segundaVersao)
          let s:oVersoes.segundaVersao = sArgumento
          continue
        endif

      endfor

      call s:Bootstrap()
      call Processar()
      return

    endif

    call s:Bootstrap()
    call s:CriarJanela()
    call s:MapKeys()

  catch
    echohl WarningMsg | echon v:exception
  endtry

endfunction

function! s:Bootstrap()

  if !filereadable('CVS/Repository')
    throw 'Diretório atual não é um plugin'
  endif

  let s:sProjeto  = split(Executar('cat CVS/Repository'))[0] . '/'
  let s:sArquivo  = expand('%')
  let s:sFileType = &filetype

  let s:sEncoding      = &encoding
  let s:sFileEncoding  = &fileencoding
  let s:sFileEncodings = &fileencodings

  call Executar(s:path . ' ' . s:sArquivo)

endfunction

function! s:LimparVersoes()

  let s:oVersoes.primeiraVersao  = ''
  let s:oVersoes.primeiraSelecao = ''
  let s:oVersoes.segundaVersao   = ''
  let s:oVersoes.segundaSelecao  = ''

endfunction

function! CloseWindow()

  if bufwinnr(s:sNome) == -1
    return
  endif

  execute bufwinnr(s:sNome) . 'wincmd w'
  execute bufwinnr(s:sNome) . 'wincmd q'

endfunction

"
" Processar, abre aba com diffs
"
function! Processar()

  try

    "let l:encontrouJanela = 0

    "for window in range(1, winnr('$'))

    "  if s:sNome == bufname(window)
    "    let l:encontrouJanela = 1
    "  endif

    "  if bufname(window)
    "    let l:encontrouJanela = 1
    "  endif

    "endfor

    if bufwinnr(s:sNome) == -1
      throw 'Erro ao processar diff, tente novamente'
    endif

    let l:sLinhaCursor = getline('.')

    if !empty(l:sLinhaCursor)
      let l:nVersaoCursor = split(l:sLinhaCursor, ' ')[0]
    endif

    " fecha janela com as versoes
    call CloseWindow()

    let l:sVersoes         = ''
    let l:sPathArquivos    = '/tmp/'
    let l:sComandoCheckout = 'cvs checkout '
    let l:sArquivo         = expand('%:t')
    let l:sSeparador       = '__'

    let l:sComandoMover    = 'mv ' . s:sProjeto . s:sArquivo . ' '. l:sPathArquivos
    let l:sComandoDiff     = 'vert diffsplit ' . l:sPathArquivos

    " Nao selecionou versao para comparar
    " Abre nova aba com versao da linha do cursor
    if empty(s:oVersoes.primeiraVersao) && !empty(l:nVersaoCursor)

      call Executar(l:sComandoCheckout . '-r ' . l:nVersaoCursor . ' '.  s:sProjeto . s:sArquivo)
      call Executar(sComandoMover . '\[' . l:nVersaoCursor . '\]\ ' . l:sArquivo)

      exe 'tabnew ' . l:sPathArquivos . '[' . l:nVersaoCursor . '] ' . l:sArquivo
      call s:ChangeFileName('[' . l:nVersaoCursor . '] ' . l:sArquivo)
      exe 'setlocal filetype=' . s:sFileType
      return

    endif

    " selecinou 1 versao apenas
    if empty(s:oVersoes.segundaVersao)

      let l:sVersoes .= ' -r ' . s:oVersoes.primeiraVersao
      let l:sOutputCheckout = Executar(l:sComandoCheckout . '-r ' . s:oVersoes.primeiraVersao . ' '.  s:sProjeto . s:sArquivo)

      if !filereadable(s:sProjeto . s:sArquivo)
        throw 'Erro - ' . l:sOutputCheckout
      endif

      call Executar(sComandoMover . '\[' . s:oVersoes.primeiraVersao . '\]\ ' . l:sArquivo)

      exe 'tabnew ' . s:sArquivo
      exe l:sComandoDiff . '[' . s:oVersoes.primeiraVersao . ']\ ' . l:sArquivo
      call s:ChangeFileName('[' . s:oVersoes.primeiraVersao . '] ' . l:sArquivo)
      exe 'setlocal filetype=' . s:sFileType

    else

      let l:sVersoes .= ' -r ' . s:oVersoes.primeiraVersao . ' -r ' . s:oVersoes.segundaVersao

      let l:sOutputCheckoutPrimeiraVersao = Executar(l:sComandoCheckout . '-r ' . s:oVersoes.primeiraVersao . ' '.  s:sProjeto . s:sArquivo)

      if !filereadable(s:sProjeto . s:sArquivo)
        throw 'Erro - ' . l:sOutputCheckoutPrimeiraVersao
      endif

      call Executar(sComandoMover . '\[' . s:oVersoes.primeiraVersao . '\]\ ' . l:sArquivo)

      let l:sOutputCheckoutSegundaVersao = Executar(l:sComandoCheckout . '-r ' . s:oVersoes.segundaVersao . ' '.  s:sProjeto . s:sArquivo)

      if !filereadable(s:sProjeto . s:sArquivo)
        throw 'Erro - ' . l:sOutputCheckoutSegundaVersao
      endif

      call Executar(sComandoMover . '\[' . s:oVersoes.segundaVersao . '\]\ ' . l:sArquivo)

      exe 'tabnew ' . l:sPathArquivos . '[' . s:oVersoes.primeiraVersao . '] ' . l:sArquivo
      call s:ChangeFileName('[' . s:oVersoes.primeiraVersao . '] ' . l:sArquivo)
      exe 'setlocal filetype=' . s:sFileType

      exe l:sComandoDiff . '[' . s:oVersoes.segundaVersao . '] ' . l:sArquivo
      call s:ChangeFileName('[' . s:oVersoes.segundaVersao . '] ' . l:sArquivo)
      exe 'setlocal filetype=' . s:sFileType

    endif

    " remove pasta do projeto criada pelo cvs checkout
    call Executar('mv -f ' . s:sProjeto . ' ' . tempname())

    " Troca lado dos splits do diff e retorna cursor pra primeiro split
    exe "normal \<C-W>L"
    exe "normal \<C-h>"

  catch
    echohl WarningMsg | echon v:exception
  endtry

endfunction

"
" Selecionar linha
"
function! Selecionar()

  let sLinha  = getline('.')
  let nVersao = split(sLinha, ' ')[0]

  " Remove selecao da primeira versao
  if ( nVersao == s:oVersoes.primeiraVersao )

    call matchdelete(s:oVersoes.primeiraSelecao)
    let s:oVersoes.primeiraVersao = ''
    return

  endif

  " Remove selecao da segunda versao
  if ( nVersao == s:oVersoes.segundaVersao )

    call matchdelete(s:oVersoes.segundaSelecao)
    let s:oVersoes.segundaVersao = ''
    return

  endif

  " ja selecionou 2 versoes, retorna funcao
  if !empty(s:oVersoes.segundaVersao) && !empty(s:oVersoes.primeiraVersao)
    return
  endif

  " seleciona primeira e segunda versao
  if empty(s:oVersoes.primeiraVersao)

    let s:oVersoes.primeiraVersao  = nVersao
    let s:oVersoes.primeiraSelecao = matchadd("WildMenu", sLinha)

  else

    let s:oVersoes.segundaVersao  = nVersao
    let s:oVersoes.segundaSelecao = matchadd("WildMenu", sLinha)

  endif

endfunction

"
" Executa um comando e retorna resposta do comando ou erro
"
function! Executar(comando)

  let l:retornoComando = system(a:comando)

  if v:shell_error
    throw l:retornoComando
  endif

  return l:retornoComando

endfunction

function! CvsDiffToggle()

  let cvsdiffWindowNumber = bufwinnr(s:sNome)

  if cvsdiffWindowNumber != -1
    call CloseWindow()
    return
  endif

  call Cvsdiff('')

endfunction

command! CvsDiffToggle call CvsDiffToggle()

" registra comando Cvsdiff que pode ter 1 ou nenhum argumento
command! -nargs=? -complete=buffer Cvsdiff call Cvsdiff("<args>")
command! -nargs=? -complete=buffer CD      call Cvsdiff("<args>")
