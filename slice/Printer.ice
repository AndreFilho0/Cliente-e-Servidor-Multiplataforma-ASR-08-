// Contrato Slice (IDL do middleware ICE) compartilhado por TODAS as linguagens.
// A partir deste unico arquivo o slice2java gera os stubs Java e o slice2py
// gera os stubs Python. Por isso um cliente Python fala com um servidor Java
// (e vice-versa) sem nenhuma linha de codigo de rede escrita a mao.
module Demo
{
    // Tipos usados pelos metodos
    sequence<long> LongSeq;

    exception InvalidArgument
    {
        string reason;
    }

    interface Printer
    {
        string printString(string s);

        string toMorse(string s);
        LongSeq collatz(long n) throws InvalidArgument;
        string toRoman(int n) throws InvalidArgument;
    }
}
