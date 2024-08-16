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
    @reactive.event(input.submit)
    def rec():
        nonlocal proc
        proc = subprocess.Popen([
            'python',
            'python-chattr/chattr.py', 
            "--prompt='hello'"
            ],
            stdout=subprocess.PIPE
            )

    @render.text
    @reactive.event(input.submit)
    def value():
        nonlocal response
        nonlocal proc
        out = ''
        rec()
        reactive.invalidate_later(1)
        if hasattr(proc, "stdout"):
            out = proc.stdout.read()
        if out:
            response = response + str(out)
        print(out)
        return response


app = App(app_ui, server)

