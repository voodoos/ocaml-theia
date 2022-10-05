img:
	docker build -t theia-ocaml .

run: img
	docker run -p 8080:8080 theia-ocaml
