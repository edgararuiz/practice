import random
import subprocess
from shiny import App, Inputs, Outputs, Session, reactive, render, ui

app_ui = ui.page_fluid(
    ui.input_text("prompt", "Prompt"),
    ui.input_task_button("submit", "Submit"),
    ui.output_text("value"),
    ui.card(id = "main")
    )

def server(input: Inputs, output: Outputs, session: Session):
    response = ''
    proc = ''
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
        out = ''
        reactive.invalidate_later(0.5)
        if hasattr(proc, "stdout"):
            out = proc.stdout.read(3)
            if out:
                if input.prompt() != '':
                    pr = "Me: " + input.prompt()
                    ui.update_text("prompt", value= "")
                    ui.insert_ui(                        
                        ui.p(pr), selector= "#main", where = "afterEnd"
                        )                        
                    pr = ''                
                out = str(out.decode())
                print(out)
                response = response + out
            else:
                if response != '':
                    response = "LLLM: " + response
                    ui.insert_ui(                        
                        ui.p(response), selector= "#main", where = "afterEnd"
                    )    
                    response = ''                
        return response


app = App(app_ui, server)


