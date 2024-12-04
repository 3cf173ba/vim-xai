let s:plugin_root = expand('<sfile>:p:h:h')
let s:vim_xai_maxlines = 10000
let g:vim_xai_complete_default_url = "https://api.x.ai/v1/chat/completions"
" let g:vim_xai_token = "put this line in your ~/.vimrc and set your token here"
let g:vim_xai_user_agent = "vim-xai/0.1"

let g:vim_xai_complete_default = '{
\  "messages": [
\     {
\       "role": "system",
\       "content": "You are Grok, a chatbot inspired by the Hitchhikers Guide to the Galaxy."
\     }
\  ],
\  "model": "grok-beta",
\  "stream": 1,
\  "temperature": 0
\}'

function! vim_xai_config#load()
  " nothing to do - triggers autoloading of this file
endfunction
