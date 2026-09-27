import sys, Ice
import Demo

MORSE = {
    'A': '.-',   'B': '-...', 'C': '-.-.', 'D': '-..',  'E': '.',    'F': '..-.',
    'G': '--.',  'H': '....', 'I': '..',   'J': '.---', 'K': '-.-',  'L': '.-..',
    'M': '--',   'N': '-.',   'O': '---',  'P': '.--.', 'Q': '--.-', 'R': '.-.',
    'S': '...',  'T': '-',    'U': '..-',  'V': '...-', 'W': '.--',  'X': '-..-',
    'Y': '-.--', 'Z': '--..',
    '0': '-----', '1': '.----', '2': '..---', '3': '...--', '4': '....-',
    '5': '.....', '6': '-....', '7': '--...', '8': '---..', '9': '----.',
}

ROMAN = [(1000, 'M'), (900, 'CM'), (500, 'D'), (400, 'CD'), (100, 'C'), (90, 'XC'),
         (50, 'L'), (40, 'XL'), (10, 'X'), (9, 'IX'), (5, 'V'), (4, 'IV'), (1, 'I')]


class PrinterI(Demo.Printer):
    def printString(self, s, current=None):
        print(s)
        return s + "*"

    # Codigo Morse: letras separadas por espaco, palavras por " / "
    def toMorse(self, s, current=None):
        print("toMorse(%r)" % s)
        words = s.upper().split()
        return " / ".join(" ".join(MORSE.get(c, '?') for c in w) for w in words)

    # Sequencia de Collatz (conjectura 3n+1) de n ate chegar em 1
    def collatz(self, n, current=None):
        print("collatz(%d)" % n)
        if n < 1:
            raise Demo.InvalidArgument("collatz exige n >= 1, recebeu %d" % n)
        seq = [n]
        while n != 1:
            n = n // 2 if n % 2 == 0 else 3 * n + 1
            seq.append(n)
        return seq

    # Numero inteiro -> algarismos romanos (1 a 3999)
    def toRoman(self, n, current=None):
        print("toRoman(%d)" % n)
        if not 1 <= n <= 3999:
            raise Demo.InvalidArgument("toRoman aceita 1..3999, recebeu %d" % n)
        result = ""
        for value, symbol in ROMAN:
            while n >= value:
                result += symbol
                n -= value
        return result


if __name__ == "__main__":
    with Ice.initialize(sys.argv) as communicator:
        adapter = communicator.createObjectAdapterWithEndpoints("SimpleAdapter", "default -p 5678")
        adapter.add(PrinterI(), Ice.Identity("SimplePrinter"))
        adapter.activate()
        print("Servidor Python ICE ouvindo em tcp -p 5678 (Ctrl+C para parar)")
        communicator.waitForShutdown()
