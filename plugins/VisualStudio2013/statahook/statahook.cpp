// statahook.cpp : Defines the exported functions for the DLL application.
//
// Notes:
/*
http://web.archive.org/web/20091228193034/http://msdn.microsoft.com/en-us/library/ms997537.aspx
https://msdn.microsoft.com/en-us/library/windows/desktop/ms644960%28v=vs.85%29.aspx?f=255&MSPPError=-2147217396#installing_releasing
https://msdn.microsoft.com/en-us/library/ms644959#wh_keyboardhook
https://msdn.microsoft.com/en-us/library/windows/desktop/ms644977%28v=vs.85%29.aspx?f=255&MSPPError=-2147217396
http://stackoverflow.com/questions/27070135/how-to-add-a-hook-to-keyboard-hookproc
http://cboard.cprogramming.com/windows-programming/136581-setwindowshookex-returns-null.html
*/

#include "stdafx.h"
#include "statahook.h"

// statahook.cpp : Defines the exported functions for the DLL application.

//c++ IO seems to cause segfaults when Stata finishes. C IO segfaults immediately.
//UnhookWindowsHookEx //Don't worry, it will get unloaded when process finishes
STATAHOOK_API LRESULT CALLBACK statafocushook(int nCode, WPARAM wParam, LPARAM lParam){
	static int c = 0;
	int dummy = 0, visible=1;
	static int last_visible = 1;
	static BOOL do_wait = FALSE, start_counting=FALSE, do_IO=FALSE;
	LONG new_style = 0, style = 0;
	LRESULT prevent = 0, other_ret;
	auto t = std::time(nullptr);
	auto tm = *std::localtime(&t);

	if (do_wait) while (dummy<500000000) dummy++;

	//std::ofstream outfile;
	//outfile.open("testhook.log", std::ios_base::app);
	//outfile << std::put_time(&tm, "%d-%m-%Y %H-%M-%S") << " ";
	switch (nCode){
	case HCBT_ACTIVATE:
		//outfile << c << "HCBT_ACTIVATE" << std::endl;
		prevent = 1;
		break;
	case HCBT_CREATEWND:
		style = ((LPCBT_CREATEWND)lParam)->lpcs->style;
		visible = style&WS_VISIBLE;
		//outfile << c << " HCBT_CREATEWND: " << wParam << " " << ((LPCBT_CREATEWND)lParam)->lpcs->lpszName << " " << (visible) << " " << (style & WS_MINIMIZE) << std::endl;
		if (!do_wait){
			if (!visible & !last_visible){
				//do_wait = TRUE;
				start_counting = TRUE;
			}
		}
		else{
			if (!visible) do_wait = FALSE;
		}
		
		new_style = style & (~WS_MINIMIZE);
		//((LPCBT_CREATEWND)lParam)->lpcs->style = new_style; //crashes
		break;
	case HCBT_MINMAX:
		//outfile << c << "HCBT_MINMAX" << LOWORD(lParam) << std::endl;
		if ((LOWORD(lParam) == SW_RESTORE) | (LOWORD(lParam) == SW_SHOW) | 
			(LOWORD(lParam) == SW_SHOWMINIMIZED) | (LOWORD(lParam) == SW_SHOWNORMAL))
			prevent = 1;
		break;
	case HCBT_MOVESIZE:
		//outfile << c << "HCBT_MOVESIZE" << std::endl;
		break;
	case HCBT_SETFOCUS:
		//outfile << c << "HCBT_SETFOCUS" << std::endl;
		prevent = 1;
		break;
	case HCBT_SYSCOMMAND:
		//outfile << c << "HCBT_SYSCOMMAND" << std::endl;
		break;

	case HCBT_QS: //The system has retrieved a WM_QUEUESYNC message from the system message queue.
		//outfile << "HCBT_QS" << std::endl;
		break;
	case HCBT_DESTROYWND: //A window is about to be destroyed.
		//outfile << "HCBT_DESTROYWND" << std::endl;
		break;
	case HCBT_KEYSKIPPED: //The system has removed a keyboard message from the system message queue.
		//outfile << "HCBT_KEYSKIPPED" << std::endl;
		break;
	case HCBT_CLICKSKIPPED: //The system has removed a mouse message from the system message queue.
		//outfile << "HCBT_CLICKSKIPPED" << std::endl;
		break;
	default:
		//outfile << "OTHER" << std::endl;
		break;
	}
	last_visible = visible;
	if (start_counting) c++;
	if (c>20) do_wait = FALSE;

	//outfile.close();
	other_ret = CallNextHookEx(NULL, nCode, wParam, lParam);
	return (prevent || other_ret);
}


