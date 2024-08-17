import random
import subprocess
from shiny import App, Inputs, Outputs, Session, reactive, render, ui

app_ui = ui.page_fluid(
    ui.layout_columns(
      ui.input_text("prompt", "Prompt"),
      ui.input_task_button("submit", "Submit"), 
      col_widths= (7, 3)
    ),
    ui.output_ui("value"),
    ui.output_ui(id = "main")
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
        reactive.invalidate_later(0.1)
        if hasattr(proc, "stdout"):
            out = proc.stdout.read(3)
            if out:
                out = str(out.decode())
                response = response + out
            else:
                if response != '':
                    ui.insert_ui(                        
                        ui.layout_columns(
                            ui.card(ui.markdown(response), full_screen=True),
                            ui.p(),
                            col_widths= (11, 1)
                            ), 
                        selector= "#main", 
                        where = "afterEnd"
                    )    
                    response = '' 

                    if input.prompt() != '':
                        pr = input.prompt()
                        ui.update_text("prompt", value= "")
                        ui.insert_ui(  
                            ui.layout_columns(
                                ui.p(), 
                                ui.card(ui.markdown(pr), full_screen=True),                                
                                col_widths= (1, 11)
                            ), 
                            selector= "#main", 
                            where = "afterEnd"
                            )                        
                        pr = ''                
               
        return ui.markdown(response)


app = App(app_ui, server)


