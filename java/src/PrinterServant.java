import com.zeroc.Ice.Current;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Implementacao (servant) da interface Slice Demo::Printer.
 * A MESMA logica de negocio do servidor Python (server.py), so que em Java.
 * Como o contrato Slice e identico, qualquer cliente (Python ou Java) fala
 * com este servant sem saber que ele foi escrito em Java.
 */
public class PrinterServant implements Demo.Printer {

    private static final Map<Character, String> MORSE = new HashMap<>();
    static {
        String[] letters = {
            "A", ".-",  "B", "-...","C", "-.-.","D", "-..", "E", ".",   "F", "..-.",
            "G", "--.", "H", "....","I", "..",  "J", ".---","K", "-.-", "L", ".-..",
            "M", "--",  "N", "-.",  "O", "---", "P", ".--.","Q", "--.-","R", ".-.",
            "S", "...", "T", "-",   "U", "..-", "V", "...-","W", ".--", "X", "-..-",
            "Y", "-.--","Z", "--..",
            "0", "-----","1", ".----","2", "..---","3", "...--","4", "....-",
            "5", ".....","6", "-....","7", "--...","8", "---..","9", "----."
        };
        for (int i = 0; i < letters.length; i += 2) {
            MORSE.put(letters[i].charAt(0), letters[i + 1]);
        }
    }

    private static final int[]    ROMAN_VALUES  = {1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1};
    private static final String[] ROMAN_SYMBOLS = {"M","CM","D","CD","C","XC","L","XL","X","IX","V","IV","I"};

    @Override
    public String printString(String s, Current current) {
        System.out.println(s);
        return s + "*";
    }

    // Codigo Morse: letras separadas por espaco, palavras por " / "
    @Override
    public String toMorse(String s, Current current) {
        System.out.println("toMorse(" + quote(s) + ")");
        String[] words = s.toUpperCase().trim().split("\\s+");
        List<String> encoded = new ArrayList<>();
        for (String w : words) {
            if (w.isEmpty()) continue;
            StringBuilder sb = new StringBuilder();
            for (char c : w.toCharArray()) {
                if (sb.length() > 0) sb.append(' ');
                sb.append(MORSE.getOrDefault(c, "?"));
            }
            encoded.add(sb.toString());
        }
        return String.join(" / ", encoded);
    }

    // Sequencia de Collatz (conjectura 3n+1) de n ate chegar em 1
    @Override
    public long[] collatz(long n, Current current) throws Demo.InvalidArgument {
        System.out.println("collatz(" + n + ")");
        if (n < 1) {
            throw new Demo.InvalidArgument("collatz exige n >= 1, recebeu " + n);
        }
        List<Long> seq = new ArrayList<>();
        seq.add(n);
        while (n != 1) {
            n = (n % 2 == 0) ? n / 2 : 3 * n + 1;
            seq.add(n);
        }
        long[] out = new long[seq.size()];
        for (int i = 0; i < out.length; i++) out[i] = seq.get(i);
        return out;
    }

    // Numero inteiro -> algarismos romanos (1 a 3999)
    @Override
    public String toRoman(int n, Current current) throws Demo.InvalidArgument {
        System.out.println("toRoman(" + n + ")");
        if (n < 1 || n > 3999) {
            throw new Demo.InvalidArgument("toRoman aceita 1..3999, recebeu " + n);
        }
        StringBuilder result = new StringBuilder();
        for (int i = 0; i < ROMAN_VALUES.length; i++) {
            while (n >= ROMAN_VALUES[i]) {
                result.append(ROMAN_SYMBOLS[i]);
                n -= ROMAN_VALUES[i];
            }
        }
        return result.toString();
    }

    private static String quote(String s) {
        return "'" + s + "'";
    }
}
