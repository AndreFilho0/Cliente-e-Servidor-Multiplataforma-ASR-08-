import sys, Ice
import Demo

# Endereco do servidor: python3 client.py <host>  (padrao: localhost)
host = sys.argv[1] if len(sys.argv) > 1 else "localhost"

with Ice.initialize(sys.argv) as communicator:
    base = communicator.stringToProxy("SimplePrinter:tcp -h %s -p 5678" % host)
    printer = Demo.PrinterPrx.checkedCast(base)
    if not printer:
        raise RuntimeError("Proxy invalido")

    printer.printString("Hello World!")

    # O mesmo codigo funciona contra o servidor Python OU o servidor Java.
    print("Morse  :", printer.toMorse("SOS ICE"))
    print("Collatz:", printer.collatz(27)[:10], "...")
    print("Romano :", printer.toRoman(2026))

    # Excecao definida no Slice, lancada no servidor e capturada no cliente
    try:
        printer.toRoman(5000)
    except Demo.InvalidArgument as e:
        print("Erro remoto:", e.reason)
