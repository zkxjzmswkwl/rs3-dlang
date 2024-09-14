package main

import "core:fmt"
import "core:strings"
import "core:os"
import w "core:sys/windows"

foreign import k32 "system:kernel32.lib"

//----------------------------------------------------------------------------------------------------
// core:sys/windows was missing this structure.
process_entry :: struct {
	dwSize: w.DWORD,
	cntUsage: w.DWORD,
	th32ProcessID: w.DWORD,
	th32DefaultHeapID: w.ULONG_PTR,
	th32ModuleID: w.DWORD,
	cntThreads: w.DWORD,
	pcPriClassBase: w.LONG,
	dwFlags: w.DWORD,
	szExeFile: [260]w.CHAR
}
//----------------------------------------------------------------------------------------------------
// core:sys/windows was missing these functions.
foreign k32 {
	// I'd imagine `---` denotes as a forward declaration? Bit weird.
	CreateToolhelp32Snapshot :: proc(dwFlags: w.DWORD, th32ProcessID: w.DWORD) -> w.HANDLE                    ---
	Process32First           :: proc(hSnapshot: w.HANDLE, lppe: ^process_entry) -> int                        ---
	Process32Next            :: proc(hSnapshot: w.HANDLE, lppe: ^process_entry) -> int                        ---
}
//----------------------------------------------------------------------------------------------------
inject_dll :: proc(process_id: u32, module_path: string) {
	fmt.println(strings.clone_to_cstring(module_path))

	module_path_cstring := strings.clone_to_cstring(module_path)
	defer delete(module_path_cstring)

	proc_handle := w.OpenProcess(0x000F000 | 0x00100000 | 0xFFFF, false, process_id)
	load_library := cast(proc "stdcall" (rawptr) -> u32)w.GetProcAddress(w.GetModuleHandleA("kernel32.dll"), "LoadLibraryA")
	remote := w.VirtualAllocEx(proc_handle, nil, len(module_path), w.MEM_RESERVE | w.MEM_COMMIT, w.PAGE_READWRITE)

	w.WriteProcessMemory(proc_handle, remote, rawptr(module_path_cstring), len(module_path), nil)
	w.CreateRemoteThread(proc_handle, nil, 0, load_library, remote, 0, nil)
	w.CloseHandle(proc_handle)
}
//----------------------------------------------------------------------------------------------------
inject_all_clients :: proc(file_name: string) -> u32 {
	process_id: w.DWORD
	pe32: process_entry
	pe32.dwSize = size_of(process_entry)

	snapshot_handle := CreateToolhelp32Snapshot(0x00000002, 0)

	if Process32First(snapshot_handle, &pe32) == 0 {
		fmt.println("k32.Process32First failed.")
	}

	/*
		This sucks. Not entirely sure how to go about taking
		an `[]u8` and get it to a place where I can perform comparisons 
		with a string. 

		The result is iterating over the characters and using Odin's string builder
		to write each byte. Even then, the result wasn't what I'd wanted.

		So fuck it `strings.contains`. ¯\_(ツ)_/¯
	*/
	for Process32Next(snapshot_handle, &pe32) == 1 {
		remote_buffer: strings.Builder
		strings.builder_init(&remote_buffer)

		for c, idx in pe32.szExeFile {
			strings.write_byte(&remote_buffer, c)
		}

		built_str := strings.to_string(remote_buffer)

		if strings.contains(built_str, file_name) {
			fmt.println("Found a client instance.")
			process_id = pe32.th32ProcessID

			dir := os.get_current_directory()
			dll_loc := strings.concatenate({dir, ".\\DeOppressoLiber.dll"})
			fmt.println(dll_loc);
			inject_dll(process_id, dll_loc)
		} 
	}

	w.CloseHandle(snapshot_handle)
	return process_id
}
//----------------------------------------------------------------------------------------------------
main :: proc() {
	inject_all_clients("rs2client.exe")
}
//----------------------------------------------------------------------------------------------------