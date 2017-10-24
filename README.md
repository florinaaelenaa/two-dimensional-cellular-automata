# two-dimensional-cellular-automata
Programul constă în realizarea unui circuit secvențial sincron care simulează execuția unui automat celular pentru o lume bidimensională finită cu dimensiunea de 64×64 de celule.

Implementarea lui constă într-un AFN (reprezentat în diagrama din pagina următoare) care în implementare are doar 3 stări, celelalte fiind pași ai execuției pe care îi urmează.

Stările mai sus menționate sunt:
- read_cell : citește câte o celulă per ciclu de ceas, până termină de parcurs o linie a lumii, după care trece în stare de procesare+scriere(write_cell) verficându-se ca și condiție ca indicele coloanei să nu depășească valoare 63
- write_cell: scrie în lume noile valori la linia curentă indicată; aceste valori sunt procesate pe baza vecinilor a căror reprezentare în binar NVCES dau în zecimal indicele la care trebuie să ne uităm în rule pentru a-i selecta valoarea
- update_done: în această stare se intră dacă s-a terminat de parcurs o generație;

Am ales implementarea doar a 3 stări propriu-zise pentru că am vrut să reduc numărul de cicli, cum fiecare tranziție dintr-o stare în alta se efectua pe un nou front de ceas crescător.

Citirea se face cu ajutorul unui buffer de 3x65 în care rețin 3 linii citite în felul următor:
- pentru starea inițială pun pe prima linie 0, pentru că matricea se consideră bordată cu 0
- pentru o stare oarecare se shiftează liniile în sus cu o poziție, pentru a întroduce pe ultima linie a bufferului, noua linie din lume
- pentru ultima linie, shiftez liniile în sus cu o poziție și pe ultima linie introduc 0-uri

De menționat este faptul că buffer-ul este bordat și în lateral cu 0-uri (de aici și dimensiunea de 65).

Procesarea se face alternativ cu citirea și simultan cu scrierea , odată ce s-a ajuns la finalul unei linii. Aceasta constă în decizia pe care trebuie să o luăm pentru noua celulă cu privire la vecinii săi:

Toate aceste instrucțiuni sunt atribuite blocant, sincron pe clock, deci fiecare nouă valoare primită de o variabilă(row,col,state, etc..) se va modifica pe noul front crescător al ceasului.

De aici rezultă și motivul pentru care am ales folosirea clk-ului pentru lista de sensibilități a always-ului(deci nu am mai separat logica combinațională de cea secvențială) pentru că toate semnalele noastre depindeau de ceas și pentru că fiecare iterație(citire/scriere) trebuia efectuată într-o perioadă diferită.
