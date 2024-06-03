if exists('g:loaded_auto_light_dark')
    finish " load only once
endif

let g:loaded_auto_light_dark = 1

let s:save_cpo = &cpo
set cpo&vim

if !exists("g:auto_light_dark_update_ms")
    let g:auto_light_dark_update_ms = 10000 " 10 seconds
endif

let s:dark_mode = "dark"
let s:light_mode = "light"

let g:interface_mode = "unknown"

function CallUserDarkMode()
    	let g:interface_mode = s:dark_mode
    	call call(function("DarkMode"), [])
endfunction

function CallUserLightMode()
    	let g:interface_mode = s:light_mode
    	call call(function("LightMode"), [])
endfunction

function AfterModeChanged()
    	if exists('g:loaded_lightline')
        	call lightline#init()
        	call lightline#colorscheme()
    	endif
    	if exists('g:loaded_airline')
		AirlineRefresh
	endif
endfunction

function DesiredInterfaceMode()
    	call system("which defaults")

    	if v:shell_error ==? 0 " if we can read stuff out of defaults
        	call system("defaults read -g AppleInterfaceStyle")

        	if v:shell_error ==? 0
            		return s:dark_mode
        	endif

        	return s:light_mode
    	endif

    	" fallback for non macos
    	if ((strftime('%H')) > 17 && (strftime('%H') < 6))
        	return s:dark_mode
    	endif

    	return s:light_mode
endfunction

function! ProcessModeChange(desired_interface_mode) abort
    	if g:interface_mode ==? a:desired_interface_mode
        	return
    	endif

    	if a:desired_interface_mode ==? s:dark_mode
        	call CallUserDarkMode()
    	else
        	call CallUserLightMode()
    	endif

    	call AfterModeChanged()
endfunction

" Handles output from the job
function! HandleOutput(job_id, data) abort
    	if a:data ==? 'Dark'
        	call ProcessModeChange(s:dark_mode)
	else
        	call ProcessModeChange(s:light_mode)
    	endif
endfunction

function! HandleExit(job_id, status) abort
endfunction

function! DesiredInterfaceModeAsync() abort
    	if executable('defaults')
        	let l:cmd = 'defaults read -g AppleInterfaceStyle'
        	call job_start(['bash', '-c', l:cmd], {
            				\ 'out_cb': 'HandleOutput',
            				\ 'err_cb': 'HandleOutput',
            				\ 'exit_cb': 'HandleExit'
        				\ })
    	else
        	" Fallback if `defaults` isn't available
        	call timer_start(0, {-> ProcessModeChange(((strftime('%H') > 17)&& (strftime('%H') < 6)) ? s:dark_mode : s:light_mode)})
    	endif
endfunction

function SetLightDarkMode(...)
	if (g:interface_mode !=? "unknown")
		call DesiredInterfaceModeAsync()
    	else
    		let l:desired_interface_mode = DesiredInterfaceMode()

    		if g:interface_mode ==? l:desired_interface_mode
        		" avoid unneeded changes to prevent screen flash
        		return
    		endif

    		if l:desired_interface_mode ==? s:dark_mode
        		call CallUserDarkMode()
    		else
        		call CallUserLightMode()
    		endif

    		call AfterModeChanged()
	endif
endfunction

call SetLightDarkMode()
call timer_start(g:auto_light_dark_update_ms, "SetLightDarkMode", {"repeat": -1})

let &cpo = s:save_cpo
unlet s:save_cpo
