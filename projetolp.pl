% 106251 - Constanca Fonseca
:- set_prolog_flag(answer_write_options, [max_depth(0)]). % para listas completas
:- ['dados.pl'], ['keywords.pl']. % ficheiros a importar


% 1 Qualidade dos dados

/*
EventosSemSala e uma lista, ordenada e sem elementos repetidos, contem os IDs dos eventos sem sala.
*/
eventosSemSalas(EventosSemSala):-
    findall(ID, evento(ID, _, _, _, semSala), Lst_Aux),
    sort(Lst_Aux, EventosSemSala).

/*
Predicado auxiliar que junta duas listas.
*/
intersecao([], _, []).
intersecao([X|R], L2, [X|Res]) :-
    memberchk(X, L2), !,  
    intersecao(R, L2, Res).
intersecao([_|R], L2, Res) :-
    intersecao(R, L2, Res).

/*
EventosSemSala e uma lista, ordenada e sem elementos repetidos, contem os IDs dos eventos sem sala que ocorrem num certo DiaSemana.
*/
eventosSemSalasDiaSemana(DiaSemana, EventosSemSala):-
    findall(ID, horario(ID, DiaSemana, _, _, _, _), L1),
    findall(ID, evento(ID, _, _, _, semSala), L2),
    intersecao(L1, L2, Lista_Auxiliar),
    sort(Lista_Auxiliar, EventosSemSala).

    
/*
EventosSemSala e uma lista, ordenada e sem elementos repetidos e contem os IDs dos eventos sem salas durante os periodos que aparecem na lista de periodos.
*/
eventosSemSalasPeriodo([],[]):-!.
eventosSemSalasPeriodo(ListaPeriodos, EventosSemSala):-
    findall(ID, (horario(ID,_,_,_,_,Periodo), member(Periodo, ListaPeriodos), evento(ID, _, _, _, semSala)), Eventos),
    findall(Id, (horario(Id,_,_,_,_,'p1_2'), evento(Id, _, _, _, semSala)), EventosSemestrais),
    append(Eventos, EventosSemestrais, Eventostds),
    sort(Eventostds, EventosSemSala).


% 2 Pesquisas simples

/* Predicado auxiliar que comparar e junta períodos */ 
periodos_de(p1_2, [p1,p2]).
periodos_de(p3_4, [p3,p4]).
periodos_de(P, [P]) :- \+ member(P, [p1_2,p3_4]).


periodo_compativel(Periodo, EventoPeriodo) :-
    periodos_de(EventoPeriodo, Lista),
    member(Periodo, Lista).
/* EventosNoPeriodo e uma lista, ordenada e sem elementos repetidos que contem os IDs dos eventos de ListaEventos que acontecem durante o Periodo. */
organizaEventos(ListaEventos, Periodo, EventosNoPeriodo) :-
    organizaEventos_aux(ListaEventos, Periodo, L),
    sort(L, EventosNoPeriodo), !.

organizaEventos_aux([], _, []).

organizaEventos_aux([ID|R], Periodo, [ID|Res]) :-
    horario(ID, _, _, _, _, EventoPeriodo),
    periodo_compativel(Periodo, EventoPeriodo),
    organizaEventos_aux(R, Periodo, Res).

organizaEventos_aux([_|R], Periodo, Res) :-
    organizaEventos_aux(R, Periodo, Res).


/*
Devolve uma lista com os IDs dos eventos com duracao menor ou igual a Duracao do input.
*/
eventosMenoresQue(Duracao, ListaEventosMenoresQue):-
    findall(ID, (horario(ID, _, _, _, Tempo, _), (Tempo =< Duracao)), L1),
    sort(L1, ListaEventosMenoresQue).

/*
Devolve True se a duracao relativa ao evento com o ID do input for menor ou igual a Duracao. Caso contrario devolve false.
*/
eventosMenoresQueBool(ID, Duracao):-
    horario(ID, _, _, _, Tempo, _),
    (Tempo =< Duracao).
    

/*
ListaDisciplinas e uma lista, ordenada com todas as disciplinas correspondentes ao Curso.
*/
procuraDisciplinas(Curso, ListaDisciplinas):-
    findall(ID, turno(ID, Curso, _, _), IDs),
    findall(NomeDisciplina,
            (member(X, IDs), evento(X, NomeDisciplina, _, _, _)),
            Nomes),
    sort(Nomes, ListaDisciplinas).

converteDisciplinaEmEventos(Dis,Id):-
    evento(Y,Dis,_,_,_),Y = Id.

organizaDisciplinas([],_,[[],[]]).
organizaDisciplinas([Disciplina|Resto],Curso,[[Disciplina|R],Random]):-
    converteDisciplinaEmEventos(Disciplina,ID),
    turno(ID,Curso,_,_),
    (horario(ID,_,_,_,_,'p1');
    horario(ID,_,_,_,_,'p2');
    horario(ID,_,_,_,_,'p1_2')),
    organizaDisciplinas(Resto,Curso,[R,Random]).
organizaDisciplinas([Disciplina|Resto],Curso,[Random,[Disciplina|R]]):-
    converteDisciplinaEmEventos(Disciplina,ID),
    turno(ID,Curso,_,_),
    (horario(ID,_,_,_,_,'p3');
    horario(ID,_,_,_,_,'p4');
    horario(ID,_,_,_,_,'p3_4')),
    organizaDisciplinas(Resto,Curso,[Random,R]).

/*
Predicado auxiliar que soma todos os elementos de uma lista.
*/
soma([], 0).
soma([X|R], Z):- soma(R, S), Z is X + S.

organizaIdsEmHoras([],[]):-!.
organizaIdsEmHoras([ID|Outros],[Horas|Res]):-
    horario(ID,_,_,_,Horas,_),
    organizaIdsEmHoras(Outros,Res).
/*
Devolve a soma total de horas dos eventos relativos ao Curso durante o Ano e durante o Periodo.
*/
horasCurso(Periodo, Curso, Ano, TotalHoras):-
    findall(ID, turno(ID, Curso, Ano, _), L1),
    sort(L1, L_aux),
    organizaEventos(L_aux, Periodo, Lista),
    organizaIdsEmHoras(Lista, L2),
    soma(L2, TotalHoras).

/*
Evolucao e uma lista de tuplos na forma (Ano, Periodo, NumHoras) onde o NumHoras e o numero total de horas relativas ao Curso durante o Ano e Periodo.
*/
evolucaoHorasCurso(Curso, Evolucao):-
    horasCurso(p1, Curso, 1, H11),
    horasCurso(p2, Curso, 1, H12),
    horasCurso(p3, Curso, 1, H13),
    horasCurso(p4, Curso, 1, H14),
    horasCurso(p1, Curso, 2, H21),
    horasCurso(p2, Curso, 2, H22),
    horasCurso(p3, Curso, 2, H23),
    horasCurso(p4, Curso, 2, H24),
    horasCurso(p1, Curso, 3, H31),
    horasCurso(p2, Curso, 3, H32),
    horasCurso(p3, Curso, 3, H33),
    horasCurso(p4, Curso, 3, H34),
    Evolucao = [
        (1,p1,H11),(1,p2,H12),(1,p3,H13),(1,p4,H14),
        (2,p1,H21),(2,p2,H22),(2,p3,H23),(2,p4,H24),
        (3,p1,H31),(3,p2,H32),(3,p3,H33),(3,p4,H34)
    ].                                


% 3 Ocupacoes criticas de salas


/* O evento acontece na sua totalidade no slot. */
ocupaSlot(HoraInicioDada, HoraFimDada, HoraInicioEvento, HoraFimEvento, Horas):-
    HoraInicioDada =< HoraInicioEvento, HoraFimDada >= HoraFimEvento,
    Horas is (HoraFimEvento - HoraInicioEvento).

/* O evento contem totalmente o slot. */
ocupaSlot(HoraInicioDada, HoraFimDada, HoraInicioEvento, HoraFimEvento, Horas):-
    HoraInicioDada >= HoraInicioEvento, HoraFimDada =< HoraFimEvento,
    Horas is (HoraFimDada - HoraInicioDada).

/* A sobreposicao apenas acontece no fim do evento. */
ocupaSlot(HoraInicioDada, HoraFimDada, HoraInicioEvento, HoraFimEvento, Horas):-
    HoraInicioDada >= HoraInicioEvento, HoraFimDada >= HoraFimEvento, HoraInicioDada < HoraFimEvento,
    Horas is (HoraFimEvento - HoraInicioDada).

/* A sobreposicao apenas acontece no principio do evento. */
ocupaSlot(HoraInicioDada, HoraFimDada, HoraInicioEvento, HoraFimEvento, Horas):-
    HoraInicioDada =< HoraInicioEvento, HoraFimDada =< HoraFimEvento,
    Horas is (HoraFimDada - HoraInicioEvento).

/* No overlap: fail */
ocupaSlot(_, HoraFimDada, HoraInicioEvento, _, _) :-
    HoraFimDada =< HoraInicioEvento, !, fail.

ocupaSlot(HoraInicioDada, _, _, HoraFimEvento, _) :-
    HoraInicioDada >= HoraFimEvento, !, fail.

/*
SomaHoras e o numero total de horas ocupadas nas salas do tipo TipoSala, no intervalo entre HoraInicio e HoraFim, no DiaSemana e no periodo Periodo.
*/
numHorasOcupadas(Periodo, TipoSala, DiaSemana, HoraInicio, HoraFim, SomaHoras):-
    salas(TipoSala, Lista),
    findall(Ids,(horario(Ids,DiaSemana,_,_,_,Periodo),evento(Ids,_,_,_,S),member(S,Lista)),LstEventos),
    findall(I,(((horario(I,DiaSemana,_,_,_,'p1_2'),(Periodo = 'p1';Periodo = 'p2'));(horario(I,DiaSemana,_,_,_,'p3_4'),(Periodo = 'p3';Periodo = 'p4'))),evento(I,_,_,_,Sa),member(Sa,Lista)),LstIds),
    append(LstEventos,LstIds,ListaEventos),
    findall(Horas,(member(Id,ListaEventos),horario(Id,_,HorasInicio,HorasFim,_,_),ocupaSlot(HoraInicio,HoraFim,HorasInicio,HorasFim,Horas)),L2),
    soma(L2, SomaHoras).

/*
Max e o numero maximo de horas que uma sala do tipo TipoSala pode ser ocupada num intervalo de tempo entre HoraInicio e HoraFim.
*/
ocupacaoMax(TipoSala, HoraInicio, HoraFim, Max):-
    salas(TipoSala, List),
    length(List, N),
    Max is ((HoraFim - HoraInicio) * N).


/*
A Percentagem obtem-se a partir da divisao entre a SomaHoras e o Max, multiplicando esse resultado por 100.
*/
percentagem(SomaHoras, Max, Percentagem):-
    Percentagem is ((SomaHoras / Max) * 100).

horasOcupada([],[],[],_,_,[]).
horasOcupada([A|Anos],[S|Sala],[D|Dia],HoraInicio,HoraFim,[Termo|Resto]):-
    numHorasOcupadas(A,S,D,HoraInicio,HoraFim,H),
    Termo = [D,S,H],
    horasOcupada(Anos,Sala,Dia,HoraInicio,HoraFim,Resto).

ocupacao([],_,_,[]):-!.
ocupacao([S|Sal],HoraInicio,HoraFim,[M|M1]):-
    ocupacaoMax(S,HoraInicio,HoraFim,M),
    ocupacao(Sal,HoraInicio,HoraFim,M1).

verificarThresholdAux([[]|[]],[],[[]|[]]):-!.
verificarThresholdAux([[casosCriticos|[_,_,H]]|R],[O|Oc],[[casosCriticos|[_,_,Per]]|Res]):-
    percentagem(H,O,Per),
    verificarThresholdAux(R,Oc,[[]|Res]).

verificarThreshold([[]|[]],_,[[]|[]]):-!.%auxiliar
verificarThreshold([[Random|[Dia,Sala,Per]]|Rest],Threshold,[[Random|[Dia,Sala,Per]]|Res]):-
    Per > Threshold,
    !,
    verificarThreshold(Rest,Threshold,[_|Res]).
verificarThreshold([_,Rest],Threshold,[_|Res]):-
    verificarThreshold(Rest,Threshold,Res).

transformaFunctores([[]|[]],[[]|[]]):-!.
transformaFunctores([El|Res],[F|F1]):-
    F =.. El,
    transformaFunctores(Res,F1).

/*
Os resultados consistem numa lista ordenada de tuplos do tipo casosCriticos(DiaSemana, TipoSala, Percentagem). A Percentagem esta acima de um valor critico, o Threshold. 
*/
ocupacaoCritica(HoraInicio,HoraFim,Threshold,Resultados):-
    findall(Salas,salas(Salas,_),TipoSalas),
    Ano = [p1,p2,p1_2,p3,p4,p3_4],
    DiaSemana = ['segunda-feira','terca-feira','quarta-feira','quinta-feira','sexta-feira'],
    horasOcupada(Ano,TipoSalas,DiaSemana,HoraInicio,HoraFim,ResultadosAux),
    ocupacao(TipoSalas,HoraInicio,HoraFim,Maximo),
    verificarThresholdAux(ResultadosAux,Maximo,ResultadosAux1),
    verificarThreshold(ResultadosAux1,Threshold,ResultadosAux2),
    transformaFunctores(ResultadosAux2,Resultados).


% 4 And now for something completely different

/*
Um predicado que escolhe o lugar a mesa de 8 pessoas. A ListaPessoas contem o nome de todas as pessoas que se vao sentar a mesa. ListaRestricoes contem um conjunto de
restricoes para que as pessoas fiquem sentadas de um forma especifica. A OcupacaoMesa e uma lista de tres listas, onde a primeira contem as pessoas de um lado da mesa
(X1, X2, X3), a segunda contem as pessoas que se vao sentar a cabeceira (X4 e X5), a terceira lista contem o nomes dos que se vao sentar do outro lado da mesa (X6, X7, X8).
*/
ocupacaoMesa(ListaPessoas, ListaRestricoes, OcupacaoMesa):-
    ListaPessoas,
    ListaRestricoes = [cab1(NomePessoa):- X4,  % pessoa que fica na cabeceira perto da lareira (X4).
    cab2(NomePessoa):- X5, % pessoa que fica na outra cabeceira.
    honra(NomePessoa1, NomePessoa2):- (X4, X6) ; (X5, X3), % a primeira e quem fica a cabeceira e a segunda fica a sua direita (X3 ou X6).
    lado(NomePessoa1, NomePessoa2):- (X1, X2); (X2, X3); (X6, X7); (X7, X8), % as duas ficam lado a lado na mesa.
    naoLado(NomePessoa1, NomePessoa2):- (X1, X3); (X6, X8), % nao ficam lado a lado na mesa.
    frente(NomePessoa1, NomePessoa2):- (X1, X6); (X2, X7); (X3, X8), % ficam frente a frente na mesa.
    naoFrente(NomePessoa1, NomePessoa2):- (X1, X7); (X1, X8); (X2, X6); (X2, X8); (X3, X6); (X3, X7)], % nao ficam frente a frente na mesa.
    OcupacaoMesa == [[X1, X2, X3],[X4, X5],[X6, X7, X8]].

