import random
import subprocess

proc = subprocess.Popen(['python','python-chattr/chattr.py', "--prompt='hello'"],stdout=subprocess.PIPE)

from shiny import App, Inputs, Outputs, Session, reactive, render, ui

app_ui = ui.page_fluid(ui.output_text("value"))

def server(input: Inputs, output: Outputs, session: Session):
    @render.text
    def value():
        reactive.invalidate_later(0.5)
        return line = proc.stdout.read()


app = App(app_ui, server)

