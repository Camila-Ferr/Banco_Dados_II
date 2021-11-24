DO $$ BEGIN
    PERFORM drop_functions();
    PERFORM drop_tables();
END $$;

create table cidade(
numero int not null primary key,
nome varchar not null
);

create table bairro(
numero int not null primary key,
nome varchar not null,
cidade int not null,
foreign key (cidade) references cidade(numero)
);

create table pesquisa(
numero int not null,
descricao varchar not null,
primary key (numero)
);

create table pergunta(
pesquisa int not null,
numero int not null,
descricao varchar not null,
primary key (pesquisa,numero),
foreign key (pesquisa) references pesquisa(numero)
);

create table resposta(
pesquisa int not null,
pergunta int not null,
numero int not null,
descricao varchar not null,
primary key (pesquisa,pergunta,numero),
foreign key (pesquisa,pergunta) references pergunta(pesquisa,numero)
);

create table entrevista(
numero int not null primary key,
data_hora timestamp not null,
bairro int not null,
foreign key (bairro) references bairro(numero)
);

create table escolha(
entrevista int not null,
pesquisa int not null,
pergunta int not null,
resposta int not null,
primary key (entrevista,pesquisa,pergunta),
foreign key (entrevista) references entrevista(numero),
foreign key (pesquisa,pergunta,resposta) references resposta(pesquisa,pergunta,numero)
);

insert into cidade values (1,'Rio de Janeiro');
insert into cidade values (2,'Niterói');
insert into cidade values (3,'São Paulo');

insert into bairro values (1,'Tijuca',1);
insert into bairro values (2,'Centro',1);
insert into bairro values (3,'Lagoa',1);
insert into bairro values (4,'Icaraí',2);
insert into bairro values (5,'São Domingos',2);
insert into bairro values (6,'Santa Rosa',2);
insert into bairro values (7,'Moema',3);
insert into bairro values (8,'Jardim Paulista',3);
insert into bairro values (9,'Higienópolis',3);


insert into pesquisa values (1,'Pesquisa 1');

insert into pergunta values (1,1,'Pergunta 1');
insert into pergunta values (1,2,'Pergunta 2');
insert into pergunta values (1,3,'Pergunta 3');
insert into pergunta values (1,4,'Pergunta 4');

insert into resposta values (1,1,1,'Resposta 1 da pergunta 1');
insert into resposta values (1,1,2,'Resposta 2 da pergunta 1');
insert into resposta values (1,1,3,'Resposta 3 da pergunta 1');
insert into resposta values (1,1,4,'Resposta 4 da pergunta 1');
insert into resposta values (1,1,5,'Resposta 5 da pergunta 1');

insert into resposta values (1,2,1,'Resposta 1 da pergunta 2');
insert into resposta values (1,2,2,'Resposta 2 da pergunta 2');
insert into resposta values (1,2,3,'Resposta 3 da pergunta 2');
insert into resposta values (1,2,4,'Resposta 4 da pergunta 2');
insert into resposta values (1,2,5,'Resposta 5 da pergunta 2');
insert into resposta values (1,2,6,'Resposta 5 da pergunta 2');

insert into resposta values (1,3,1,'Resposta 1 da pergunta 3');
insert into resposta values (1,3,2,'Resposta 2 da pergunta 3');
insert into resposta values (1,3,3,'Resposta 3 da pergunta 3');

insert into resposta values (1,4,1,'Resposta 1 da pergunta 4');
insert into resposta values (1,4,2,'Resposta 2 da pergunta 4');

insert into entrevista values (1,'2020-03-01'::timestamp,1);
insert into escolha values (1,1,1,2);
insert into escolha values (1,1,2,2);
insert into escolha values (1,1,3,1);

insert into entrevista values (2,'2020-03-01'::timestamp,1);
insert into escolha values (2,1,1,3);
insert into escolha values (2,1,2,1);
insert into escolha values (2,1,3,2);

insert into entrevista values (3,'2020-03-01'::timestamp,1);
insert into escolha values (3,1,1,4);
insert into escolha values (3,1,2,1);
insert into escolha values (3,1,3,1);

insert into entrevista values (4,'2020-03-01'::timestamp,1);
insert into escolha values (4,1,1,2);
insert into escolha values (4,1,2,1);
insert into escolha values (4,1,3,1);

insert into entrevista values (5,'2020-03-01'::timestamp,1);
insert into escolha values (5,1,1,2);
insert into escolha values (5,1,2,1);
insert into escolha values (5,1,3,1);

CREATE FUNCTION perguntas(pesquisa integer) RETURNS integer[] AS $$
    DECLARE
        perguntas integer[];
        p RECORD;
    BEGIN
        FOR p IN (  SELECT pergunta.numero
                    FROM pergunta JOIN pesquisa ON (pergunta.pesquisa = pesquisa.numero)
                    GROUP BY pergunta.numero
                    ORDER BY pergunta.numero ASC) LOOP
        perguntas = perguntas || p.numero;
        END LOOP;
        RETURN perguntas;
    END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION frequencia(elemento integer, vetor integer[]) RETURNS real AS $$
    DECLARE
        freq_absoluta real = 0;
        n real = cardinality(vetor);
    BEGIN
        FOR i IN 1..n LOOP
            IF (vetor[i] = elemento) THEN
                freq_absoluta = freq_absoluta + 1;
            END IF;
        END LOOP;
        RETURN freq_absoluta / n;
    END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION alt(pg integer) RETURNS integer[] AS $$
    DECLARE
        alte integer[];
    BEGIN
        SELECT array_agg(numero) INTO alte
        FROM resposta
        WHERE (pergunta = pg)
        GROUP BY pesquisa, pergunta;
        RETURN alte;
    END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION rl(pq integer, pg integer, p_bairros varchar[], p_cidades varchar[]) RETURNS integer[] AS $$
    DECLARE
        rl integer[];
    BEGIN
        WITH aux1 AS (
            SELECT pesquisa, pergunta, resposta, bairro
            FROM escolha JOIN entrevista ON (escolha.entrevista = entrevista.numero)
        ), aux2 AS (
            SELECT pesquisa, pergunta, resposta, bairro, bairro.nome as bairro_nome, cidade as cidade_id
            FROM aux1 JOIN bairro ON (aux1.bairro = bairro.numero)
        ), aux3 AS (
            SELECT pesquisa, pergunta, resposta, bairro_nome, cidade.nome as cidade_nome
            FROM aux2 JOIN cidade ON (aux2.cidade_id = cidade.numero)
        ), aux4 AS (
            SELECT *
            FROM aux3
            WHERE (bairro_nome = ANY(p_bairros) OR cidade_nome = ANY(p_cidades))
        )   SELECT array_agg(resposta) INTO rl
            FROM aux3
            WHERE (pesquisa = pq AND pergunta = pg)
            GROUP BY pesquisa, pergunta;
        RETURN rl;
    END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION resultado(pesquisa integer, p_bairros varchar[], p_cidades varchar[]) RETURNS TABLE(pergunta integer, hs real[]) AS $$
    DECLARE
        histo real[];
        respostas integer[];
        alternativa integer;
        p integer;
    BEGIN
        CREATE TEMPORARY TABLE relacao (pergunta integer, histo real[]);

        IF ((p_bairros IS NULL) OR (p_cidades IS NULL)) THEN
            FOREACH p IN ARRAY perguntas(pesquisa) LOOP

                SELECT array_agg(resposta) INTO respostas
                FROM escolha
                WHERE (pesquisa = id_pesquisa AND pergunta = id_pregunta)
                GROUP BY pesquisa, pergunta;
      
                IF (respostas IS NOT NULL) THEN
                    FOREACH alternativa IN ARRAY alt(p) LOOP
                        histo := array_cat(hs, ARRAY[ ARRAY[alternativa::real, frequencia(alternativa, respostas)] ]);
                    END LOOP;
                    INSERT INTO relacao VALUES(p, hs);
                    histo = '{}';
                END IF;
            END LOOP;
        ELSE
            FOREACH p IN ARRAY perguntas(pesquisa) LOOP
                respostas = rl(pesquisa, p, p_bairros, p_cidades);
                IF (respostas IS NOT NULL) THEN
                    FOREACH alternativa IN ARRAY alt(p) LOOP
                        histo = histo || ARRAY[ ARRAY[alternativa::real, frequencia(alternativa, respostas)] ];
                    END LOOP;
                    INSERT INTO relacao VALUES(p, histo);
                    histo = '{}';
                END IF;
            END LOOP;
        END IF;
        RETURN QUERY
        SELECT * FROM relacao;
    END;
$$ LANGUAGE plpgsql;

SELECT * FROM resultado(1, ARRAY['Lagoa'], ARRAY['Rio de Janeiro', 'Niteroi']);
