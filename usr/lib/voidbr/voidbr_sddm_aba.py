# -*- coding: utf-8 -*-
#
#   voidbr_sddm_aba.py
#   Created: seg 23 nov 2026 01:40:00 -04
#   Updated: seg 23 nov 2026 01:55:22 -04
#
#   Copyright (c) 2026, Vilmar Catafesta <vcatafesta@gmail.com>
#   Copyright (c) 2026, VoidLinuxBR Team
#   Assembled By Vilmar Catafesta for the VoidBR project.
#   All rights reserved.
#
#   ChangeLog:
#   - v1.0 (2026-11-23): Versão inicial — aba "Tela de login" compartilhada
#     pelos voidbr-*-tweaks (sway, labwc, xfce, gnome, enlightenment): temas
#     do SDDM com prévia, Testar (sddm-greeter --test-mode), fundo próprio e
#     Aplicar pelo pkexec voidbr-sddm-theme.
#   - v1.1 (2026-11-23): Um Aplicar só: nos tweaks com "✅ Aplicar" geral
#     (criar_aba(janela, com_botao=False)) é ele que troca a tela de login;
#     antes a aba tinha um botão próprio no fim da página e o Aplicar geral
#     dizia "Nada mudou". pendente() / aplicar() / ocupado para o app usar.
#
#   Licença BSD (a mesma dos voidbr-*-tweaks).
##############################################################################
"""
Aba "Tela de login" dos VoidBR Tweaks.

Uso no app (GTK4):
    sys.path.insert(0, "/usr/lib/voidbr")
    import voidbr_sddm_aba
    aba = voidbr_sddm_aba.criar_aba(janela, com_botao=False)   # Gtk.Widget

    com_botao=False: o app tem um "Aplicar" geral; no clique dele, chame
        if aba.pendente(): aba.aplicar()
    e não mostre "Nada mudou" enquanto aba.ocupado for True.
    com_botao=True (padrão): a aba tem o próprio botão Aplicar.

A troca de tema é do sistema (afeta todos os usuários), por isso vai pelo
"pkexec voidbr-sddm-theme aplicar", que pede a senha de administrador.
"""

import os
import re
import shutil
import subprocess
import threading

import gi

gi.require_version("Gtk", "4.0")
from gi.repository import Gtk, GLib, Gio  # noqa: E402

VERSAO = "1.1"
AJUDANTE = "/usr/bin/voidbr-sddm-theme"
PAPEL_EXT = (".avif", ".jpg", ".jpeg", ".png", ".webp", ".svg")

CSS = """
.cartao-tema { background: #2a2b3a; border-radius: 12px; padding: 8px; border: 2px solid transparent; }
.cartao-tema:hover { border-color: #4b4e66; }
flowboxchild:selected .cartao-tema { border-color: #7aa2f7; background: #2f3450; }
flowboxchild:selected, flowboxchild:focus { background: transparent; outline: none; }
.nome-tema { font-weight: bold; color: #f1f1f1; }
.tema-em-uso { color: #9ece6a; font-size: 11px; font-weight: bold; }
.sem-previa { background: #1a1b26; border-radius: 8px; color: #565f89; }
"""


def ajudante(*args):
    try:
        r = subprocess.run([AJUDANTE, *args], capture_output=True, text=True, timeout=15)
        return r.stdout if r.returncode == 0 else ""
    except (OSError, subprocess.TimeoutExpired):
        return ""


def temas():
    """[(nome, título, prévia ou "", qt)] dos temas instalados."""
    lista = []
    for linha in ajudante("listar").splitlines():
        partes = linha.split("|")
        if len(partes) == 4:
            lista.append(tuple(partes))
    return sorted(lista, key=lambda t: t[1].lower())


def greeter(qt):
    """sddm-greeter-qt6 para tema Qt6; sddm-greeter (Qt5) para os outros."""
    nomes = ["sddm-greeter-qt6", "sddm-greeter"] if qt == "6" else ["sddm-greeter",
                                                                      "sddm-greeter-qt6"]
    for n in nomes:
        if shutil.which(n):
            return n
    return None


def papel_sugerido():
    """O papel de parede do usuário, se der para saber (link do VoidBR)."""
    for c in ("~/.local/share/backgrounds/current", "~/.local/share/backgrounds/void.png"):
        c = os.path.realpath(os.path.expanduser(c))
        if os.path.isfile(c) and c.lower().endswith(PAPEL_EXT):
            return c
    return ""


class AbaLogin(Gtk.Box):
    def __init__(self, janela, com_botao=True):
        super().__init__(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        self.janela = janela
        self.com_botao = com_botao
        self.ocupado = False
        for lado in ("top", "bottom", "start", "end"):
            getattr(self, f"set_margin_{lado}")(14)
        prov = Gtk.CssProvider()
        prov.load_from_data(CSS.encode("utf-8"))
        Gtk.StyleContext.add_provider_for_display(janela.get_display(), prov,
                                                  Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION + 2)

        secao = Gtk.Label(label="Tema da tela de login", xalign=0)
        secao.add_css_class("secao")
        self.append(secao)
        dica = Gtk.Label(label="A tela onde se digita a senha ao ligar o computador. Vale para "
                               "todos os usuários e pede a senha de administrador.",
                         xalign=0, wrap=True)
        dica.add_css_class("dica")
        self.append(dica)

        self.grade = Gtk.FlowBox(selection_mode=Gtk.SelectionMode.SINGLE, homogeneous=True,
                                 max_children_per_line=3, min_children_per_line=2,
                                 column_spacing=10, row_spacing=10)
        self.grade.connect("selected-children-changed", lambda *_: self._ao_escolher())
        self.append(self.grade)

        secao2 = Gtk.Label(label="Fundo", xalign=0)
        secao2.add_css_class("secao")
        self.append(secao2)
        linha = Gtk.Box(spacing=10)
        r = Gtk.Label(label="Usar uma imagem minha no fundo", xalign=0, hexpand=True)
        r.add_css_class("rotulo-campo")
        self.w_papel = Gtk.Switch(valign=Gtk.Align.CENTER)
        self.w_papel.connect("notify::active", lambda *_: self._atualizar_papel())
        linha.append(r)
        linha.append(self.w_papel)
        self.append(linha)
        linha2 = Gtk.Box(spacing=10)
        self.l_papel = Gtk.Label(xalign=0, hexpand=True, wrap=True)
        self.l_papel.add_css_class("dica")
        self.b_papel = Gtk.Button(label="📂 Escolher imagem…")
        self.b_papel.connect("clicked", self._escolher_imagem)
        linha2.append(self.l_papel)
        linha2.append(self.b_papel)
        self.append(linha2)
        self.papel = papel_sugerido()

        self.st = Gtk.Label(xalign=0, wrap=True)
        caixa = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        caixa.add_css_class("caixa-status")
        caixa.append(self.st)
        self.append(caixa)

        botoes = Gtk.Box(spacing=8, halign=Gtk.Align.END)
        self.b_testar = Gtk.Button(label="👁️ Testar",
                                   tooltip_text="Abre o tema numa janela, sem sair da sessão. "
                                                "Feche a janela para voltar.")
        self.b_testar.add_css_class("botao-azul")
        self.b_testar.connect("clicked", lambda *_: self._testar())
        botoes.append(self.b_testar)
        self.b_aplicar = None
        if com_botao:
            self.b_aplicar = Gtk.Button(label="🔐 Aplicar na tela de login")
            self.b_aplicar.add_css_class("botao-verde")
            self.b_aplicar.connect("clicked", lambda *_: self.aplicar())
            botoes.append(self.b_aplicar)
        self.append(botoes)

        self.recarregar()

    # ----- temas -----

    def _cartao(self, nome, titulo, previa, em_uso):
        caixa = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        caixa.add_css_class("cartao-tema")
        if previa:
            img = Gtk.Picture.new_for_filename(previa)
            if hasattr(img, "set_content_fit"):
                img.set_content_fit(Gtk.ContentFit.COVER)
            img.set_size_request(200, 112)
        else:
            img = Gtk.Label(label="sem prévia\n(use Testar)", justify=Gtk.Justification.CENTER)
            img.add_css_class("sem-previa")
            img.set_size_request(200, 112)
        caixa.append(img)
        rotulo = Gtk.Label(label=titulo, xalign=0, ellipsize=3)
        rotulo.add_css_class("nome-tema")
        caixa.append(rotulo)
        uso = Gtk.Label(label="✔ em uso" if em_uso else nome, xalign=0)
        uso.add_css_class("tema-em-uso" if em_uso else "dica")
        caixa.append(uso)
        return caixa

    def recarregar(self):
        if not os.access(AJUDANTE, os.X_OK):
            self.status("⚠️ voidbr-sddm-theme não encontrado (pacote voidbr-sddm-themes).")
            self._botoes(False)
            return
        while (filho := self.grade.get_first_child()) is not None:
            self.grade.remove(filho)
        self.lista = temas()
        self.atual = ajudante("atual").strip()
        for i, (nome, titulo, previa, _qt) in enumerate(self.lista):
            self.grade.append(self._cartao(nome, titulo, previa, nome == self.atual))
            if nome == self.atual:
                self.grade.select_child(self.grade.get_child_at_index(i))
        # fundo próprio já aplicado neste tema? (theme.conf.user do voidbr-sddm-theme)
        self.papel_inicial = ""
        if self.atual:
            dir_tema = f"/usr/share/sddm/themes/{self.atual}"
            try:
                with open(f"{dir_tema}/theme.conf.user", encoding="utf-8") as f:
                    if f.readline().startswith("# voidbr-sddm-theme"):
                        for arq in os.listdir(dir_tema):
                            if arq.startswith("voidbr-papel."):
                                self.papel_inicial = f"{dir_tema}/{arq}"
            except OSError:
                pass
        if self.papel_inicial:
            self.papel = self.papel_inicial
        self.w_papel.set_active(bool(self.papel_inicial))
        self._atualizar_papel()
        dica = "" if self.com_botao else " Escolha outro e use o ✅ Aplicar lá embaixo."
        self.status(f"✔ Tema atual: {self.atual or 'padrão do SDDM'}.{dica}")

    def escolhido(self):
        sel = self.grade.get_selected_children()
        if not sel:
            return None
        return self.lista[sel[0].get_index()]

    def _ao_escolher(self):
        t = self.escolhido()
        if t:
            extra = "" if t[0] != self.atual else " (é o que está em uso)"
            onde = "Aplicar troca" if self.com_botao else "o ✅ Aplicar lá embaixo troca"
            self.status(f"Escolhido: {t[1]}{extra}. Testar mostra antes; {onde}.")

    # ----- fundo -----

    def _atualizar_papel(self):
        ligado = self.w_papel.get_active()
        self.b_papel.set_sensitive(ligado)
        if not ligado:
            self.l_papel.set_text("Fica o fundo próprio do tema.")
        elif self.papel:
            self.l_papel.set_text(os.path.basename(self.papel))
        else:
            self.l_papel.set_text("Escolha a imagem.")

    def _escolher_imagem(self, *_):
        dlg = Gtk.FileDialog(title="Fundo da tela de login", modal=True)
        filtro = Gtk.FileFilter()
        filtro.set_name("Imagens")
        for ext in PAPEL_EXT:
            filtro.add_pattern("*" + ext)
            filtro.add_pattern("*" + ext.upper())
        filtros = Gio.ListStore.new(Gtk.FileFilter)
        filtros.append(filtro)
        dlg.set_filters(filtros)
        pasta = os.path.dirname(self.papel) if self.papel else \
            GLib.get_user_special_dir(GLib.UserDirectory.DIRECTORY_PICTURES)
        if pasta and os.path.isdir(pasta):
            dlg.set_initial_folder(Gio.File.new_for_path(pasta))

        def fim(d, res):
            try:
                arq = d.open_finish(res)
            except GLib.Error:
                return
            if arq.get_path():
                self.papel = arq.get_path()
                self._atualizar_papel()
        dlg.open(self.janela, None, fim)

    # ----- botões -----

    def status(self, texto):
        self.st.set_text(texto)
        return False

    def _botoes(self, ligados):
        self.b_testar.set_sensitive(ligados)
        if self.b_aplicar is not None:
            self.b_aplicar.set_sensitive(ligados)

    def pendente(self):
        """True se a tela mostra algo diferente do que está aplicado."""
        t = self.escolhido()
        if not t or not os.access(AJUDANTE, os.X_OK):
            return False
        ligado = self.w_papel.get_active()
        if t[0] != self.atual or ligado != bool(self.papel_inicial):
            return True
        return ligado and self.papel != self.papel_inicial

    def _testar(self):
        t = self.escolhido()
        if not t:
            self.status("ℹ️ Escolha um tema primeiro.")
            return
        prog = greeter(t[3])
        if not prog:
            self.status("⚠️ sddm-greeter não encontrado.")
            return
        try:
            subprocess.Popen([prog, "--test-mode", "--theme", f"/usr/share/sddm/themes/{t[0]}"],
                             stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL,
                             stderr=subprocess.DEVNULL, start_new_session=True)
            self.status(f"👁️ Testando {t[1]}: feche a janela do teste para voltar.")
        except OSError as e:
            self.status(f"⚠️ {e}")

    def _avisar(self, texto):
        """Status na aba e, sem botão próprio, também na linha do app."""
        self.status(texto)
        if not self.com_botao and hasattr(self.janela, "status"):
            self.janela.status(texto)
        return False

    def aplicar(self):
        t = self.escolhido()
        if not t:
            self.status("ℹ️ Escolha um tema primeiro.")
            return
        cmd = ["pkexec", AJUDANTE, "aplicar", t[0]]
        if self.w_papel.get_active():
            if not self.papel:
                self._avisar("ℹ️ Tela de login: escolha a imagem do fundo (ou desligue a opção).")
                return
            cmd += ["--papel", self.papel]
        else:
            cmd += ["--sem-papel"]
        self._botoes(False)
        self.ocupado = True
        self._avisar("🔐 Tela de login: esperando a senha de administrador…")

        def tarefa():
            try:
                r = subprocess.run(cmd, capture_output=True, text=True)
                ok, msg = r.returncode == 0, (r.stderr or r.stdout).strip()
                if r.returncode in (126, 127) and not msg:
                    msg = "senha não confirmada"
            except OSError as e:
                ok, msg = False, str(e)
            GLib.idle_add(self._fim, ok, t, msg)
        threading.Thread(target=tarefa, daemon=True).start()

    def _fim(self, ok, t, msg):
        self._botoes(True)
        self.ocupado = False
        if ok:
            self.recarregar()
            self._avisar(f"✅ Tela de login: {t[1]}. Aparece no próximo login ou ao reiniciar.")
        else:
            limpo = re.sub(r"\x1b\[[0-9;]*m", "", msg) or "erro desconhecido"
            self._avisar(f"⚠️ Tela de login não trocou: {limpo}")
        return False


def criar_aba(janela, com_botao=True):
    return AbaLogin(janela, com_botao)
