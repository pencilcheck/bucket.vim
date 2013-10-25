scriptencoding utf-8

if &cp || exists('g:loaded_bucket')
  finish
endif

" Exit quicky if running in compatible mode
if &compatible
  echohl ErrorMsg
  echohl none
  finish
endif

if !has("ruby")
  echohl ErrorMsg
  echo "Sorry, Bucket.vim requires Vim to be compiled with Ruby support."
  echohl none
  finish
endif

if exists('ruby_version')
  unlet ruby_version
endif

redir => ruby_version
  silent ruby print RUBY_VERSION
redir END

let ruby_version = split(ruby_version)[0]

if ruby_version < "2.0.0"
  echohl ErrorMsg
  echo "Sorry, Bucket.vim requires Ruby support version 2.0.0 and above."
  echohl none
  finish
endif

if v:version < 700
    echohl WarningMsg
    echomsg 'Bucket: Vim version is too old, Bucket requires at least 7.0'
    echohl none
    finish
endif
let g:loaded_bucket = 1

function! s:init_var(var, value) abort
    if !exists('g:bucket_' . a:var)
        execute 'let g:bucket_' . a:var . ' = ' . string(a:value)
    endif
endfunction

let s:options = [
    \ ['left', 0],
    \ ['width', 40]
\ ]

for [opt, val] in s:options
    call s:init_var(opt, val)
endfor
unlet s:options

function s:ShowBindingWindow(filename)
  ruby $bucket.show_binding_window
endfunction

command! -nargs=? -complete=dir BucketToggle call <SID>ShowBindingWindow(<q-args>)

ruby << EOF
  # require ruby files
  ::VIM::evaluate('&runtimepath').to_s.split(',').each do |path|
   lib = "#{path}/ruby"
    if !$LOAD_PATH.include?(lib) and File.exists?(lib) and lib.include?('bucket')
      $LOAD_PATH << lib
    end
  end
  require 'bucket/bucket'
  $bucket = Bucket::Bucket.new
EOF
