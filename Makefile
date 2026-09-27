# ============================================================================
# ASR 08 - Cliente e Servidor Multiplataforma (middleware ICE 3.8)
# Suporte a macOS e Linux (Arch). Alvos principais:
#
#   make setup          -> prepara Python (venv + zeroc-ice) e baixa o jar Java
#   make py-server      -> sobe o servidor Python  (porta 5678)
#   make py-client      -> roda o cliente  Python  (HOST=<ip> opcional)
#   make java-server    -> sobe o servidor Java
#   make java-client    -> roda o cliente  Java    (HOST=<ip> opcional)
#
# Os 4 cenarios cross-language saem de combinar servidor de uma linguagem com
# cliente de outra. Ex.: 'make java-server' num terminal + 'make py-client'
# noutro = cliente Python contra servidor Java.
# ============================================================================

ICE_VERSION := 3.8.3
PORT        := 5678
HOST        ?= localhost

# ---- Python -----------------------------------------------------------------
VENV := $(CURDIR)/.venv
PY   := $(VENV)/bin/python
PIP  := $(VENV)/bin/pip

# ---- Java (detecta javac/java) ---------------------------------------------
# No macOS o /usr/bin/javac e apenas um stub sem runtime, e o openjdk do brew
# e keg-only (nao entra no PATH). Por isso preferimos, nesta ordem:
#   1) $JAVA_HOME/bin  2) openjdk do brew  3) java_home do sistema  4) PATH
BREW_JDK := /opt/homebrew/opt/openjdk/bin
SYS_JDK  := $(shell /usr/libexec/java_home 2>/dev/null)
define find_java
$(shell \
  if [ -n "$(JAVA_HOME)" ] && [ -x "$(JAVA_HOME)/bin/$(1)" ]; then echo "$(JAVA_HOME)/bin/$(1)"; \
  elif [ -x "$(BREW_JDK)/$(1)" ]; then echo "$(BREW_JDK)/$(1)"; \
  elif [ -n "$(SYS_JDK)" ] && [ -x "$(SYS_JDK)/bin/$(1)" ]; then echo "$(SYS_JDK)/bin/$(1)"; \
  else command -v $(1) 2>/dev/null || echo $(1); fi)
endef
JAVAC := $(call find_java,javac)
JAVA  := $(call find_java,java)

ICE_JAR     := java/lib/ice-$(ICE_VERSION).jar
ICE_JAR_URL := https://repo1.maven.org/maven2/com/zeroc/ice/$(ICE_VERSION)/ice-$(ICE_VERSION).jar
JAVA_OUT    := java/out
CP          := $(JAVA_OUT):$(ICE_JAR)

.DEFAULT_GOAL := help

.PHONY: help
help:
	@echo "ASR 08 - middleware ICE $(ICE_VERSION) (Python <-> Java)"
	@echo ""
	@echo "  make setup         Prepara tudo (venv Python + jar Java + build Java)"
	@echo "  make py-server     Servidor Python  (porta $(PORT))"
	@echo "  make py-client     Cliente  Python  [HOST=<ip>]"
	@echo "  make java-server   Servidor Java    (porta $(PORT))"
	@echo "  make java-client   Cliente  Java    [HOST=<ip>]"
	@echo "  make test          Roda os 4 cenarios automaticamente (smoke test)"
	@echo "  make regen         Regera os stubs Slice (Python e Java)"
	@echo "  make check         Mostra as ferramentas detectadas"
	@echo "  make clean         Remove venv, jar e build Java"
	@echo ""
	@echo "Cenarios cross-language (2 terminais):"
	@echo "  1) make java-server   +   make py-client     (cliente Py -> servidor Java)"
	@echo "  2) make py-server     +   make java-client   (cliente Java -> servidor Py)"

# ----------------------------------------------------------------------------
.PHONY: setup
setup: venv jar java-build
	@echo ">> Setup completo."

# ---- Python -----------------------------------------------------------------
.PHONY: venv
venv: $(PY)
$(PY):
	@echo ">> Criando venv e instalando zeroc-ice..."
	python3 -m venv $(VENV)
	$(PIP) install --upgrade pip >/dev/null
	$(PIP) install -r python/requirements.txt
	@echo ">> Python pronto: $(PY)"

.PHONY: py-server
py-server: venv
	cd python && $(PY) server.py

.PHONY: py-client
py-client: venv
	cd python && $(PY) client.py $(HOST)

# ---- Java -------------------------------------------------------------------
.PHONY: jar
jar: $(ICE_JAR)
$(ICE_JAR):
	@echo ">> Baixando Ice for Java $(ICE_VERSION)..."
	@mkdir -p java/lib
	curl -fSL "$(ICE_JAR_URL)" -o "$(ICE_JAR)"
	@echo ">> Jar salvo em $(ICE_JAR)"

.PHONY: java-build
java-build: $(ICE_JAR)
	@echo ">> Compilando Java com $(JAVAC)..."
	@mkdir -p $(JAVA_OUT)
	$(JAVAC) -cp "$(ICE_JAR)" -d $(JAVA_OUT) java/generated/Demo/*.java java/src/*.java
	@echo ">> Build Java pronto em $(JAVA_OUT)"

.PHONY: java-server
java-server: java-build
	$(JAVA) -cp "$(CP)" Server

.PHONY: java-client
java-client: java-build
	$(JAVA) -cp "$(CP)" Client $(HOST)

# ---- Regeneracao dos stubs (opcional) --------------------------------------
.PHONY: regen
regen: venv
	@echo ">> Regerando stubs Python (slice2py)..."
	$(VENV)/bin/slice2py --output-dir python slice/Printer.ice
	@echo ">> Obtendo slice2java e regerando stubs Java..."
	bash scripts/get-slice2java.sh
	tools/slice2java --output-dir java/generated slice/Printer.ice
	@echo ">> Stubs regerados."

# ----------------------------------------------------------------------------
.PHONY: test
test: setup
	@echo ">> Rodando os 4 cenarios automaticamente..."
	bash scripts/smoke-test.sh

.PHONY: check
check:
	@echo "JAVAC : $(JAVAC)"; $(JAVAC) -version 2>&1 | sed 's/^/        /' || true
	@echo "JAVA  : $(JAVA)";  $(JAVA)  -version 2>&1 | head -1 | sed 's/^/        /' || true
	@echo "PY    : $(PY)"
	@test -f $(ICE_JAR) && echo "ICEJAR: $(ICE_JAR) (ok)" || echo "ICEJAR: ausente (rode 'make jar')"

.PHONY: clean
clean:
	rm -rf $(VENV) $(JAVA_OUT) java/lib/*.jar tools/slice2java tools/slice-tools.jar
	find . -name __pycache__ -type d -prune -exec rm -rf {} +
	@echo ">> Limpo."
