# ASR 08 — Cliente e Servidor Multiplataforma (middleware ICE)

Implementação de **dois cenários cliente/servidor multiplataforma** sobre o
middleware **ICE (ZeroC Ice 3.8)**, continuando a Tarefa ASR 07
([RPC-Multiplataforma-ICE-Middleware](../RPC-Multiplataforma-ICE-Middleware--ASR-06-)):

1. **Cliente em Python → Servidor em Java**
2. **Cliente em Java → Servidor em Python**

O mesmo contrato Slice (`slice/Printer.ice`) é usado pelas duas linguagens: a
partir dele o `slice2py` gera os *stubs* Python e o `slice2java` gera os *stubs*
Java. Como o middleware define um protocolo de fio e uma serialização comuns,
**qualquer cliente conversa com qualquer servidor**, independentemente da
linguagem — sem uma única linha de código de rede escrita à mão.

A interface remota é a mesma da ASR 07:

| Método | Assinatura Slice | O que faz |
|---|---|---|
| `printString` | `string printString(string s)` | Imprime a string no servidor e devolve `s + "*"` |
| `toMorse` | `string toMorse(string s)` | Converte texto para código Morse |
| `collatz` | `LongSeq collatz(long n) throws InvalidArgument` | Sequência de Collatz (3n+1) de `n` até 1 |
| `toRoman` | `string toRoman(int n) throws InvalidArgument` | Inteiro (1..3999) para algarismos romanos |

A exceção `InvalidArgument` é **definida no contrato Slice**, lançada no servidor
(em Java ou Python) e capturada no cliente (em Python ou Java) como uma exceção
nativa da linguagem — este é um dos pontos mais fortes da comparação com sockets
crus (ver [Discussão](#discussão-middleware-vs-camada-de-transporte)).

---

## Estrutura do repositório

```
.
├── slice/Printer.ice        # contrato único (IDL) do middleware
├── python/
│   ├── server.py            # servidor Python
│   ├── client.py            # cliente  Python
│   ├── requirements.txt     # zeroc-ice==3.8.3
│   └── Demo/                # stubs gerados por slice2py (commitados)
├── java/
│   ├── src/                 # Server.java, Client.java, PrinterServant.java
│   ├── generated/Demo/      # stubs gerados por slice2java (commitados)
│   ├── lib/                 # ice-3.8.3.jar (baixado pelo Makefile)  [git-ignored]
│   └── out/                 # .class compilados                       [git-ignored]
├── scripts/
│   ├── smoke-test.sh        # testa os 4 combos automaticamente
│   └── get-slice2java.sh    # baixa o slice2java (só para regerar stubs)
└── Makefile                 # build/run fácil no macOS e no Linux
```

> Os *stubs* (`python/Demo/` e `java/generated/Demo/`) **já vêm commitados**.
> Assim, para apenas **rodar**, você não precisa instalar os compiladores Slice —
> só o runtime do ICE em cada linguagem.

---

## Pré-requisitos e instalação

Você precisa de: **Python 3** (com o pacote `zeroc-ice`) e um **JDK** (17+). O
`Makefile` cuida do `zeroc-ice` (via venv) e do jar do ICE para Java (baixa do
Maven Central). Só o JDK precisa estar instalado no sistema.

### macOS (Homebrew)

```bash
brew install openjdk         # JDK (Java)
# Python 3 normalmente já existe; se não: brew install python
make setup                   # cria venv + zeroc-ice, baixa o jar, compila o Java
```

> O `openjdk` do Homebrew é *keg-only* (não entra no PATH). **Não precisa
> configurar nada**: o `Makefile` detecta o JDK em `/opt/homebrew/opt/openjdk/bin`
> automaticamente.

### Arch Linux

```bash
sudo pacman -S jdk-openjdk python   # JDK + Python
make setup
```

> No Arch o `zeroc-ice` é instalado via `pip` dentro do venv (há *wheel* pronto
> para as versões recentes de Python; não precisa compilar). O jar do Java é
> baixado do Maven Central pelo `Makefile`.

### Conferir o ambiente

```bash
make check      # mostra o javac/java detectado, o python do venv e o jar
```

---

## Como executar

Use **dois terminais** (servidor num, cliente noutro). Se cliente e servidor
estiverem em **máquinas diferentes** (ex.: servidor no Arch, cliente no macOS),
passe o IP do servidor com `HOST=<ip>` no cliente e **libere a porta TCP 5678**
no servidor.

### Cenário 1 — Cliente Python → Servidor Java

```bash
# Terminal 1 (servidor Java)
make java-server

# Terminal 2 (cliente Python)
make py-client                 # local
make py-client HOST=192.168.0.10   # servidor em outra máquina
```

### Cenário 2 — Cliente Java → Servidor Python

```bash
# Terminal 1 (servidor Python)
make py-server

# Terminal 2 (cliente Java)
make java-client
make java-client HOST=192.168.0.10
```


### Saída esperada (cliente)

```
Morse  : ... --- ... / .. -.-. .
Collatz: [27, 82, 41, 124, 62, 31, 94, 47, 142, 71] ...
Romano : MMXXVI
Erro remoto: toRoman aceita 1..3999, recebeu 5000
```

### Saída esperada (servidor)

```
Hello World!
toMorse('SOS ICE')
collatz(27)
toRoman(2026)
toRoman(5000)
```

### Teste automático dos 4 cenários

```bash
make test        # sobe/derruba servidores e roda os 4 combos, reportando OK/FALHA
```

Resultado esperado:

```
[OK] cliente py -> servidor py
[OK] cliente java -> servidor py
[OK] cliente py -> servidor java
[OK] cliente java -> servidor java
RESULTADO: 4 OK, 0 FALHA
```

---

## Regerar os stubs (opcional)

Só é necessário se você **alterar o `Printer.ice`**. Os stubs commitados já
correspondem ao contrato atual.

```bash
make regen
```

Isso usa o `slice2py` (que vem no pacote `zeroc-ice` do venv) e baixa o
`slice2java` correto para a sua plataforma (`scripts/get-slice2java.sh`, extraído
do plugin oficial *Slice Tools* do ZeroC).

---

## Problemas comuns

| Sintoma | Causa provável | Solução |
|---|---|---|
| `ConnectionRefusedException` / `ConnectionRefused` | servidor parado, IP errado ou porta 5678 bloqueada | suba o servidor; confira `HOST`; libere a porta 5678 |
| `Address already in use` / `BindException` | outro servidor já usa a 5678 | pare o servidor anterior (Ctrl+C) |
| `No module named 'Ice'` | venv não criado/instalado | `make setup` (usa `.venv`) |
| `Unable to locate a Java Runtime` (macOS) | JDK não instalado | `brew install openjdk` |
| stubs desatualizados após editar `.ice` | não regerou | `make regen` |

---

## Discussão: middleware vs. camada de transporte


Neste trabalho um cliente Python fala com um servidor Java (e vice-versa) trocando strings, um inteiro, um `long`, uma sequência de longs e uma exceção de aplicação, tudo declarado uma única vez em `Printer.ice`. Construir exatamente isso diretamente sobre a camada de transporte, com sockets TCP crus, significaria reescrever à mão, e em cada linguagem, tudo o que o ICE já resolve.

O ponto central é a serialização dos dados. Sobre TCP trafegam apenas bytes, então seria necessário inventar um formato de fio próprio: como codificar um `int` ou um `long` (tamanho, sinal, ordem dos bytes), como delimitar strings (comprimento mais UTF-8) e como representar a `sequence<long>` (contagem mais elementos). Como Python e Java têm modelos de tipos diferentes, sendo o inteiro do Python de precisão arbitrária e os inteiros do Java fixos em 32 ou 64 bits, a incompatibilidade apareceria justamente no ponto de integração. Com o middleware o contrato Slice é a fonte única da verdade: o `slice2py` e o `slice2java` geram a serialização correta e coerente nos dois lados, com a mesma codificação Ice no fio. Foi por isso que o `collatz(27)` chegou idêntico em Python e em Java sem nenhuma linha de marshalling escrita por mim.

Além da serialização, há o enquadramento das mensagens e o modelo de invocação. TCP é um fluxo contínuo de bytes e não tem noção de mensagem, o que exigiria criar delimitadores ou prefixos de tamanho, um laço de leitura que remonta requisições e respostas parciais e um esquema para casar cada resposta com a requisição correspondente. O ICE entrega isso pronto na forma de RPC: a chamada `printer.toRoman(2026)` se parece com uma chamada de método local, e o proxy cuida de empacotar os argumentos, enviar, aguardar e devolver o resultado, deixando o código de negócio praticamente igual ao de um programa local.

A propagação de erros entre linguagens é outro ganho concreto. No socket cru um erro no servidor viraria, na melhor das hipóteses, uma string que o cliente precisaria reconhecer e reinterpretar, sem tipo e sem estrutura. No ICE a exceção `InvalidArgument` é declarada no próprio contrato, de modo que, lançada no servidor em Java ou Python, ela cruza a rede e é capturada no cliente como uma exceção nativa da linguagem, com seus campos preservados. Isso ficou visível no teste, em que o `toRoman(5000)` no servidor virou um bloco de tratamento de exceção no cliente.

O middleware também organiza a localização e o endereçamento dos objetos. Com sockets, saber onde está o serviço se resume a um par de host e porta com um protocolo combinado informalmente. O ICE trabalha com proxies e identidades de objeto, como em `SimplePrinter:tcp -h <host> -p 5678`, o que permite múltiplos objetos por servidor, verificação de tipo no momento da conexão, quando o `checkedCast` confirma que o objeto implementa a interface esperada, e evolução futura para recursos como facets e IceGrid.

Resumindo os benefícios, o uso do ICE nos deu tipos bem definidos e verificados nos dois lados, todos gerados a partir de um único contrato Slice, o que dispensou escrever qualquer serialização à mão. A chamada remota passou a ter aparência de método local, já que o proxy cuida de empacotar os argumentos, enviar, esperar e devolver o resultado, e os erros ganharam tipo próprio ao atravessar a fronteira entre cliente e servidor, pois a exceção declarada no contrato é lançada em uma linguagem e capturada como exceção nativa na outra. Ganhamos também identidade de objeto e binding tipado verificado, em que o checkedCast confirma que o objeto remoto implementa a interface esperada, e, acima de tudo, independência de linguagem e de plataforma: os quatro combos possíveis, isto é, Python com Python, Python com Java, Java com Python e Java com Java, rodam com os mesmos dois programas de cada lado porque todos falam o mesmo protocolo do ICE, de modo que adicionar uma nova linguagem seria apenas gerar novos stubs. Por fim, a manutenção ficou mais segura, já que ao mudar a interface basta editar o Printer.ice e regerar os stubs com make regen, e o compilador passa a apontar, em Java e em Python, onde o código deixou de estar de acordo com o contrato.

Resumindo os custos, o middleware não é de graça. Ele adiciona uma dependência externa, que é o runtime do ICE em cada linguagem mais os compiladores Slice, e traz uma curva de aprendizado dos seus conceitos, como Slice, proxies e adapters, além de exigir que cliente e servidor usem versões compatíveis de Ice. Há ainda um acoplamento à tecnologia e ao fornecedor escolhidos e uma pequena sobrecarga de processamento e latência em relação a um protocolo mínimo feito sob medida. O balanço final é um trade-off: para um protocolo trivial, ponto a ponto e em uma única linguagem, o socket cru pode ser suficiente, mas em um cenário multiplataforma e com tipos e erros ricos como o deste trabalho o middleware elimina uma grande quantidade de código repetitivo e propenso a erros, sendo justamente o que torna a interoperabilidade entre Python e Java praticamente automática.

