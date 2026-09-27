import com.zeroc.Ice.Communicator;
import com.zeroc.Ice.ObjectAdapter;
import com.zeroc.Ice.Util;

/**
 * Servidor ICE em Java.
 * Publica um objeto "SimplePrinter" na porta TCP 5678, exatamente como o
 * servidor Python. O middleware cuida de sockets, framing, serializacao,
 * despacho de metodos e mapeamento de excecoes.
 */
public class Server {
    public static void main(String[] args) {
        // try-with-resources garante communicator.destroy() no fim.
        try (Communicator communicator = Util.initialize(args)) {
            ObjectAdapter adapter =
                communicator.createObjectAdapterWithEndpoints("SimpleAdapter", "default -p 5678");
            adapter.add(new PrinterServant(), Util.stringToIdentity("SimplePrinter"));
            adapter.activate();
            System.out.println("Servidor Java ICE ouvindo em tcp -p 5678 (Ctrl+C para parar)");
            communicator.waitForShutdown();
        }
    }
}
