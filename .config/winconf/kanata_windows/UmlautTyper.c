#include <windows.h>

int main(int argc, char *argv[]) {
    if (argc < 2) return 1;

    char c = argv[1][0];

    // XOR logic: uppercase if (CapsLock XOR Shift)
    BOOL upper = ((GetKeyState(VK_CAPITAL) & 1) != 0) ^ ((GetKeyState(VK_SHIFT) & 0x8000) != 0);

    WCHAR unicode;
    switch (c) {
    case 'o': unicode = upper ? 0x00D6 : 0x00F6; break; // Ö : ö
    case 'u': unicode = upper ? 0x00DC : 0x00FC; break; // Ü : ü
    case 'a': unicode = upper ? 0x00C4 : 0x00E4; break; // Ä : ä
    case 's': unicode = upper ? 0x1E9E : 0x00DF; break; // ẞ : ß
    default: return 1;
    }

    INPUT inputs[2] = {0};
    inputs[0].type = INPUT_KEYBOARD;
    inputs[0].ki.wScan = unicode;
    inputs[0].ki.dwFlags = KEYEVENTF_UNICODE;
    inputs[1] = inputs[0];
    inputs[1].ki.dwFlags = KEYEVENTF_UNICODE | KEYEVENTF_KEYUP;

    SendInput(2, inputs, sizeof(INPUT));
    Sleep(10);
    return 0;
}
