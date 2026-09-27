import com.zeroc.Ice.Communicator;
import com.zeroc.Ice.ObjectPrx;
import com.zeroc.Ice.Util;
import java.util.Arrays;

/**
 * Cliente ICE em Java.
 * Uso: java ... Client <host>   (padrao: localhost)
 * Chama os metodos remotos como se fossem locais; o proxy gerado esconde
 * toda a comunicacao. O mesmo codigo funciona contra o servidor Java OU o
 * servidor Python, sem alteracao.
 */
public class Client {
    public static void main(String[] args) throws Demo.InvalidArgument {
        try (Communicator communicator = Util.initialize(args)) {
            String host = args.length > 0 ? args[0] : "localhost";

            ObjectPrx base = communicator.stringToProxy("SimplePrinter:tcp -h " + host + " -p 5678");
            Demo.PrinterPrx printer = Demo.PrinterPrx.checkedCast(base);
            if (printer == null) {
                throw new RuntimeException("Proxy invalido");
            }

            printer.printString("Hello World!");

            System.out.println("Morse  : " + printer.toMorse("SOS ICE"));
            long[] c = printer.collatz(27);
            System.out.println("Collatz: " + Arrays.toString(Arrays.copyOf(c, Math.min(10, c.length))) + " ...");
            System.out.println("Romano : " + printer.toRoman(2026));

            // Excecao definida no Slice, lancada no servidor e capturada no cliente
            try {
                printer.toRoman(5000);
            } catch (Demo.InvalidArgument e) {
                System.out.println("Erro remoto: " + e.reason);
            }
        }
    }
}
