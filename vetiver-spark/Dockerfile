FROM rstudio/r-session-complete:jammy
RUN /opt/R/4.4.0/bin/R -e 'install.packages("tidyverse", repos="https://packagemanager.rstudio.com/cran/__linux__/jammy/latest")' 
RUN /opt/R/4.4.0/bin/R -e 'install.packages("sparklyr", repos="https://packagemanager.rstudio.com/cran/__linux__/jammy/latest")' 
RUN /opt/R/4.4.0/bin/R -e 'install.packages("pysparklyr", repos="https://packagemanager.rstudio.com/cran/__linux__/jammy/latest")' 
RUN /opt/R/4.4.0/bin/R -e 'install.packages("chattr", repos="https://packagemanager.rstudio.com/cran/__linux__/jammy/latest")' 
RUN /opt/R/4.4.0/bin/R -e 'install.packages("DBI", repos="https://packagemanager.rstudio.com/cran/__linux__/jammy/latest")' 
RUN /opt/R/4.4.0/bin/R -e 'install.packages("odbc", repos="https://packagemanager.rstudio.com/cran/__linux__/jammy/latest")' 
RUN /opt/R/4.4.0/bin/R -e 'reticulate::install_python(version = "3.10")' 

# docker run -it databricks /bin/bash
# docker build . -f Dockerfile -t databricks
