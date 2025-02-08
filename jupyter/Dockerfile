FROM python:3.8-slim

RUN pip install jupyter matplotlib nbformat

WORKDIR /workspace

COPY configs.yaml .
COPY generate_notebook.py .
COPY start.sh .

RUN mkdir /results

RUN chmod +x start.sh

EXPOSE 8888

CMD ["./start.sh"]
