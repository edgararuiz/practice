import random
import subprocess

proc = subprocess.Popen(['python','python-chattr/chattr.py', "--prompt='what is the tallest mountain?'"],stdout=subprocess.PIPE)

from shiny import App, Inputs, Outputs, Session, reactive, render, ui

app_ui = ui.page_fluid(ui.output_text("value"))

def server(input: Inputs, output: Outputs, session: Session):
    response = ''
    @render.text
    def value():
        nonlocal response
        reactive.invalidate_later(2)
        out = proc.stdout.read()
        if out:
            response = response + str(out)
        return response


app = App(app_ui, server)

