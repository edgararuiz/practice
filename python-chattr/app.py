import random
import subprocess
from shiny import App, Inputs, Outputs, Session, reactive, render, ui

app_ui = ui.page_fluid(
    ui.input_text("prompt", "Prompt"),
    ui.input_task_button("submit", "Submit"),
    ui.output_text("value")
    )

def server(input: Inputs, output: Outputs, session: Session):
    response = ''
    proc = ''
    times = 0
    @reactive.effect
    @reactive.event(input.submit)
    def _():
        nonlocal proc
        args = [
            'python',
            'python-chattr/chattr.py', 
            f"--prompt='" + str(input.prompt()) + "'"
            ]
        proc = subprocess.Popen(
            args,
            stdout=subprocess.PIPE
            )

    @render.text
    def value():
        nonlocal response
        nonlocal proc
        nonlocal times
        out = ''
        reactive.invalidate_later(0.1)
        if hasattr(proc, "stdout"):
            out = proc.stdout.read(1)
            if out:
                ui.update_text("prompt", value= "")
                times = times + 1
                print(times)
                response = response + str(out)            
        return response


app = App(app_ui, server)


