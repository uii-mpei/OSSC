---
title: СПО. ЛР № 6. Окружение компилятора
lang: ru

---

# Цель работы

1. Знать основные понятия и фазы трансляции программ в машинный код.
2. Уметь пользоваться отдельными программами из окружения компилятора
    для пофазовой трансляции и анализа ее результатов.




# Введение

## Область применения навыков

Прикладное программирование обычно происходит в среде разработки, где сборка
программы выполняется одной командой.  Окружение компилятора представляет
для разработчика «черный ящик», на входе которого файлы исходного кода,
на выходе — исполняемый файл.  Однако иногда требуется знать, как работает
сборка изнутри:

* При использовании специфичных функций системного API (например, сетевых)
    можно столкнуться с подобными ошибками:

    ``` text
    C:\Temp\gcch23Yr.o:main.c:(.text+0xa): undefined reference to `connect'
    ```

    Их нельзя исправить в исходном коде — необходимо знать, что они поступают
    от компоновщика (линкера), и для решения проблемы нужно указать ему
    дополнительные библиотеки для подключения (возможно, в той же среде
    разработки).

* Программирование микроконтроллеров (не programmable logic controller, PLC,
    а micro-controller unit, MCU) происходит в специфичном окружении:
    операционная система отсутствует, память строго ограничена, а стандартная
    библиотека имеется в урезанном виде.  Вследствие этого исполняемый файл
    должен иметь строго определенный формат и состав. Необходимо досканально
    понимать процесс его сборки для уверенности в том, что он корректен
    и не включает лишнего кода в результат-прошивку.

* Решение некоторых системных задач: отладка аварийно завершившихся программ
    (post-mortem debug), модификация работающего кода (live patching)
    и других требует базового понимания того, как выглядит машинный код.

Программирование ОС и драйверов безусловно требует знания окружения
компилятора, однако выходит за рамки дисциплины.

В ходе работы не рассматриваются решения прикладных задач (они требуют слишком
специфичных знаний), а изучается практическое воплощение процесса трансляции
при помощи конкретного окружения компилятора (toolchain) и его инструментов.



## Фазы трансляции

Вспомним основные фазы трансляции программы из исходного кода в исполняемый.
Здесь и далее подразумевается C как структурно простой и употребительный.

1. **Фаза препроцессора (preprocessing)**

    Выполняется над каждой единицей трансляции (файлом `*.c`). \
    *Вход:* исходный код файла, исходный код заголовочных файлов. \
    *Выход:* единый файл исходного кода для компиляции.

    Для языка C на место директивы `#include` подставляется содержимое
    включаемых файлов и делаются другие замены.  И препроцессор, и компилятор
    далее делают лексический анализ.

2. **Фаза ассемблера (необязательная)**

    *Вход:* исходный код на языке высокого уровня. \
    *Выход:* исходный код на языке ассемблера.

    Язык ассемблера структурно похож на машинный код, но является его
    текстовым представлением с некоторыми удобствами.  Ассемблерный код
    зависит от целевой платформы (набора инструкций процессора).

3. **Фаза компилятора**

    Выполняется над каждым файлом-результатом работы препроцессора. \
    *Вход:* исходный код на языке ассемблера или на языке высокого уровня. \
    *Выход:* объектный файл.

    Объектный файл содержит три ключевых компонента: объектный код, таблицу
    релокаций и таблицу символов.  Объектный код — это по сути машинный код,
    но в нем вызовы функций, которых нет в данной единице трансляции, заменены
    метками. Таблица релокаций перечисляет такие функции и места их вызова.
    Таблица символов, наоборот, перечисляет функции, код которых есть в файле.

    До генерации объектного файла код может проходить скрытые стадии:
    промежуточное представление, оптимизации и другие — в современных
    компиляторах бывают десятки стадий.  Наблюдать их возможно, но требуется
    только разработчикам компиляторов.

4. **Фаза компоновки (линкера)**

    *Вход:* 1) все объектные файлы программы, 2) системный объектный код,
        3) внешние программные библиотеки. \
    *Выход:* исполняемый файл или библиотека.

    Сопоставляются таблицы символов и таблицы релокаций всех объектных файлов
    и библиотек, чтобы заменить в отъектном коде метки вызова внешних функций
    на их ральные адреса.  Для результирующего файла заполняются служебные
    таблицы и заголовки.




# Практика

Необходимо создать отдельный каталог для экспериментов и запустить в нем
командную строку.  В ней нужно добавить каталог компилятора в список путей
для поиска исполняемых файлов:

``` shell
set PATH=C:\MinGW\mingw32\bin;%PATH%
```

Далее рекомендуется для каждого практического эксперимента создавать новый
подкаталог и работать в нем.



## Фазы трансляции

Выполним отдельно каждую фазу трансляции программы `source.c`:

``` c
#include <stdio.h>

int main() {
    puts("Hi!");
    return 0;
}
```

Запустим препроцессор с выводом результатов в `preprocessed.c`:

``` shell
cpp  source.c  -o preprocessed.c
```

Подсчитав количество строк в нем, можно видеть, что размер включенного кода
стандартной библиотеки намного больше самой программы:

``` shell
find /c /v "" preprocessed.c
```

Преобразуем препроцессированный исходный код в ассемблерный листинг:

``` shell
gcc -S  preprocessed.c  -o assembler.S
```

Его размер значительно меньше, чем у препроцессированного кода: тот состоит
в основном из объявлений функцией, типов и структур, а эти сущность есть
только на этапе компиляции.  Внутри ассемблерного листинга можно заметить
имя `_puts` и строку `"Hi!"`.

Скомпилируем ассемблерный код в объектный файл:

``` shell
as  assembler.S  -o object.o
```

Компоновка — самая зависимая от транслятора и платформы часть.  Теоретически
было бы достаточно вызвать компоновщик (линкер) `ld`, передав ему объектный
файл и указав добавить стандартную библиотеку (`-lc`):

``` shell
ld  object.o  -lc  -o program.exe
```

Однако на практике для данной связки (Windows, MingGW) произойдет ошибка:

``` text
object.o:preprocessed.c:(.text+0xa): undefined reference to `__main'
object.o:preprocessed.c:(.text+0x16): undefined reference to `puts'
```

Не хватает кода стандартной библиотеки, библиотек компилятора и операционной
системы. Правильная команда такова (символы `^` означают, что команда
продолжается на следующей строке):

``` shell
ld -o program.exe ^
    C:\MinGW\mingw32\i686-w64-mingw32\lib\crt2.o ^
    C:\MinGW\mingw32\i686-w64-mingw32\lib\crtbegin.o ^
    object.o ^
    C:\MinGW\mingw32\i686-w64-mingw32\lib\crtend.o ^
    -LC:\MinGW\mingw32\lib\gcc\i686-w64-mingw32\8.1.0 ^
    -LC:\MinGW\mingw32\i686-w64-mingw32\lib ^
    -lmingw32 -lgcc -lmsvcrt -lkernel32 -lmingwex
```

* Первая строка вызывает компоновщик, чтобы создать файл `program.exe`.
* Объектные файлы, кроме кода самой программы `object.o`, — объектный код
    среды выполнения программ на C (C run-time).
* Два аргумента `-L...` задают пути, по которым располагаются библиотеки.
* В последней строке перечисляются библиотеки.  Из них `kernel32` — системная,
    остальные относятся к компилятору и стандартной библиотеке C.

Наконец можно запустить программу и убедиться, что она работает:

``` shell
program.exe
```



## Трансляция в машинный код

Рассмотрим детально, как программа `simple.c` транслируется в исполняемый файл:

``` c
#include <stdio.h>

int main() {
    puts("Hi!");
    return 0;
}
```


### Фаза препроцессора

В наборе программ GCC обращаться к препроцессору, компилятору, ассемблеру
и компоновщику (линкеру) принято через единую программу `gcc`, передавая ей
разные флаги.  Например, препроцессор запускается как `gcc -E`.

Запустим препроцессор с выводом результатов в `preprocessed.c`:

``` shell
cpp  simple.c  -o preprocessed.c
```

Найдем строки, на которых упоминается функция `puts()` (пробел в начале
предотвращает нахождение также `fputs()`):

``` shell
find /n " puts" preprocessed.c
```

Результат:

``` text
---------- SIMPLE.GCC-E.TXT
[395]  int __attribute__((__cdecl__)) puts(const char *_Str);
[885]    puts("Hi!");
```

Первая строка (395) — объявление, находящееся в `<stdio.h>`, вторая (885) —
вызов из `simple.c`.  Атрибут здесь определяет, каким образом функция должна
вызываться в машинном коде.


### Фаза компилятора

Задача:

1. Получить из исходного кода объектный код.
2. Просмотреть таблицу релокаций и убедиться,
    что в ней присутствует ссылка на `puts()`.
3. Просмотреть ассемблерный листинг машинного кода и убедиться,
    что вызов `puts()` связан с записью в таблице релокаций.

Скомпилируем программу сразу объектный код `simple.o`:

``` shell
gcc -c  -g  simple.c  -o simple.o
```

Здесь ключ `-c` указывает, что вызывается компилятор, а `-g` требует включить
в файл отладочную информацию, в частности, это таблица соответствий машинных
инструкций в объектном файле строкам исходного кода на С.

Просмотрим информацию об объектном файле:

``` shell
objdump -f simple.o
```

Первая строка вывода сообщает о формате файла:

``` text
simple.o:     file format pe-i386
```

* `pe` — portable executable, стандартный формат для Windows; в \*nix
    стандартным является ELF (Extensible Linking Format);
* `i386` означает 32-разрядную архитектуру, для 64 бит будет `x86_64`.

Вторая и третья строки говорят об архитектуре машинного кода (например,
PE для 64-битной системы может содержать 32-разрядный код) и о ключевых
чертах файла:

``` text
architecture: i386, flags 0x00000039:
HAS_RELOC, HAS_DEBUG, HAS_SYMS, HAS_LOCALS
```

* `HAS_RELOC` - в файле имеется таблица релокаций, где перечислены места
    в машинном коде, в которые компоновщик должен будет подставить реальные
    адреса функций.  То есть в самой таблице релокаций указано, в какое место
    объектного кода подставить адрес то или иной функции, а в объектном коде
    просто оставлено место для адреса.

* `HAS_DEBUG`, `HAS_SYMS`, `HAS_LOCALS` — в файле присутствует отладочная
    информация, сведения о символах (именах функций) и локальных переменных.

Наконец, в четвертой строке указано, что выполнение программы начинается
с кода, находящегося по логическому адресу 0:

``` text
start address 0x00000000
```

Объектный файл состоит из секций: для данных, для кода, для отладочной
информации и других.  Основной машинный код программы находится в секции
`.text`.  Именно от ее начала отсчитывается логический адрес кода.

Распечатаем таблицу релокаций для секции `.text`:

``` shell
objdump -r -j .text --demangle simple.o
```

В таблице релокаций три столбца:

`RELOCATION RECORDS FOR [.text]:`\
`OFFSET   TYPE              VALUE`\
<font color="#f00">`0000000a`</font> `DISP32            __main`\
<font color="#4c4">`00000011`</font> `dir32             .rdata`\
<font color="#00f">`00000016`</font> `DISP32            puts`

* Смещение (`OFFSET`): по какому смещению от начала секции `.text` находятся
    байты, подлежащие замене при работе компоновщика.

* Тип (`TYPE`): на что именно должен компоновщик заменить указанные байты.
    Для функций это `DISP32` (displacement, 32 бита), то есть смещение кода
    вызываемоей функции от начала секции (кода этот код будет подставлен).

* Значение (`VALUE`): для функций это их имя с подчеркиванием в начале.

Ключ `--demangle` здесь и далее необходим, чтобы имена отображались
в оригинальном виде (`puts`, а не `_puts`).  Искажение имен (name mangling)
делается компилятором для нужд компоновщика, подробные причины и способы
выходят за рамки этой работы.

Итак, мы убедились, что функция `puts()` действительно импортируется.
Записи о `___main` и `.rdata` рассмотрим позднее.

Просмотрим таблицу экспорта:

``` shell
nm -g --defined-only --demangle simple.o
```

Её вывод `00000000 T main` означает, что по смещению 0 (в секции `.text`)
определен код (`T`) для символа (функции) `main`.

**Примечание.**  Принятые форматы объектных файлов, подход к описанию релокаций,
типы записей о релокации сильно разнятся между операционными системами.
О формате portable executable и конкретно о формате объектных файлов COFF
можно подробно прочитать [в документации Microsoft][pe] (но редко нужно).

[pe]: https://docs.microsoft.com/en-us/windows/desktop/debug/pe-format


### Фаза ассемблера

Распечатаем машинный код с указанием, из какой строки исходного кода созданы
те или иные инструкции:

``` shell
objdump -S --demangle simple.o
```

Ассемблерный листинг состоит из трех столбцов:

* Смещение инструкции в шестнадцатеричном виде (`0:`, `1:`, `3:`).

* Байты, которыми представлена инструкция (`55`, `89 e5`).
    Видно, что смещение очередной инструкции получается прибавлением
    к смещению предыдущей количества байтов, составляющих предудущую.

* Текстовая запись инструкции на языке ассемблера.  Она состоит из команды
    (кода операции, opcode) и аргументов через запятую.  Например,
    по смещеную 1 находится команда `mov`, её аргументы - `%esp` и `%ebp`.

Строки исходного кода не являются частью листинга, они выводятся для удобства.

**Примечание.**  Утилиты MinGW (GCC) выводят ассемблерный листинг в так
называемом синтаксисе AT&T.  Другой типовой синтаксис ассемблера — Intel.
Переключать синтаксис можно ключом `-M`, например, `-Mintel`.

Первая строка листинга указывает, что по смещению 0 находится метка `main`,
то есть код функции `main()` начинается по этому смещению:

``` text
00000000 <main>:
```

Заметим, что это совпадает с начальным адресом, который показывала `objdump`.

Рассмотрим сразу вызов `puts()`:

`puts("Hi!");`\
`   e:   c7 04 24` <font color="#4c4">`00 00 00 00`</font>`    movl   $0x0,(%esp)`\
`  15:   e8` <font color="#00f">`00 00 00 00`</font>`          call   1a <main+0x1a>`

Инструкция по смещению `0x15` — вызов функции.  Её код `0xE8` занимает 1 байт,
а следующие четыре байта по смещению `0x15 + 0x01 = 0x16` должны содержать
адрес вызываемой функции, но содержат 0.  Обратимся к таблице релокаций:
по смещению `0x16` компоновщик должен записать относительный адрес `puts()`.
Таком образом, машинный код действительно обращается к `puts()`,
но не напрямую.

По смещению `0x0E` находится инструкция, которая помещает в стек адрес.
Длина инструкции — 3 байта, адрес находится по смещению `0x0E + 0x03 = 0x11`.
В таблице релокаций есть запись для этого смещения:

`OFFSET   TYPE              VALUE`\
<font color="#4c4">`00000011`</font>` dir32             .rdata`

Тип `dir32` (direction, 32 бита) означает, что на это место нужно подставить
адрес секции `.rdata` (read-only data — данные только для чтения, то есть
константы).  Аргументом `puts("Hi!")` является константа `"Hi!"`.
Проверим, что она и находится в начале секции `.rdata`:

``` shell
objdump -r -j .rdata simple.o
```

Действительно, в секции находятся четыре байта — коды символов `H`, `i`, `!`
и завершающий `'\0'` (справа показывается читаемый текст):

``` text
Contents of section .rdata:
 0000 48692100                             Hi!.
```

Для полноты рассмотрим оставшийся код.

Первые инструкции тела `main()` являются так называемым прологом функции
(function prologue).  Для целей работы работы достаточно знать, что он обязан
присутствовать и его цель — поместить в регистр процессора `%esp` (stack
pointer) адрес памяти для локальных переменных и параметров, передаваемых
в вызываемые функции.

``` text
int main() {
   0:   55                      push   %ebp
   1:   89 e5                   mov    %esp,%ebp
   3:   83 e4 f0                and    $0xfffffff0,%esp
   6:   83 ec 10                sub    $0x10,%esp
```

По смещению 9 находится инструкция вызова функции:

`   9:   e8 `<font color="#f00">`00 00 00 00`</font>`          call   e <main+0xe>`

По аналогии с `puts()` в таблице релокаций указано, что по смещению `0xA`
компоновщик должен будет записать относительный адрес функции `__main()`
(не путать с `main()`).  Это подпрограмма инициализации (initialization
routine): по правилам C на момент вызова функции `main()` должна пройти
инициализация глобальных переменных — её код и генерируется компилятором
в скрытой функции `__main()`.

Для возврата 0 из `main()` значение 0 помещается в регистр `%eax`:

``` text
return 0;
  1a:   b8 00 00 00 00          mov    $0x0,%eax
}
```

Остаток кода — эпилог функции (`leave`, `ret`) и выравнивание размера кода
до кратного четырем байтам (инструкция `nop` ничего не делает).

``` text
  1f:   c9                      leave
  20:   c3                      ret
  21:   90                      nop
  22:   90                      nop
  23:   90                      nop
```


### Фаза компоновщика

Вызов `ld` не отличается от предыдущего пункта.  Воспользуемся командой `nm`,
чтобы найти, в каких файлах находится код функции `puts()` и `__main()`:

``` shell
nm C:\MinGW\mingw32\i686-w64-mingw32\lib\libmsvcrt.a | find "puts"
nm C:\MinGW\mingw32\lib\gcc\i686-w64-mingw32\8.1.0\libgcc.a | find "__main"
```



## Трансляция в байт-код

Рассмотрим трансляцию в байт-код на примере Python.  Запустим интерактивную
оболочку и определим функцию:

``` python
def square(x):
    print(x * x)
```

Дизассемблируем функцию:

``` python
import dis
dis.dis(square)
```

Python не гарантирует, что между версиями и системами байт-код не будет
меняться, поэтому разберем конкретный вывод для Python 3.7.2:

``` text
  1            0 LOAD_GLOBAL              0 (print)
               2 LOAD_FAST                0 (x)
               4 LOAD_FAST                0 (x)
               6 BINARY_MULTIPLY
               8 CALL_FUNCTION            1
              10 POP_TOP
              12 LOAD_CONST               0 (None)
              14 RETURN_VALUE

```

Число 1 слева — номер строки, на которой определена функция.  Столбец чисел
перед инструкциями — их смещения.  После имен инструкций идут числа-индексы
в массиве ее локальных переменных, используемых ею глобальных переменных
или использованных констант (зависит от инструкции).  В скобках даны
комментарии, что именно является операндом, то есть расшифровка индекса.

Просмотрим списки, на которые ссылается функция:

``` python
>>> square.__code__.co_consts
(None,)
>>> square.__code__.co_varnames
('x',)
>>> square.__code__.co_names
('print',)
```

Виртуальная машина Python стековая.  Стек — это область памяти, доступ
к которой организован как к стопке (stack): можно положить значение на вершину
стека (push) или забрать значение с вершины (pop).

Функция работает так (в скобках дано состояние стека от вершины ко дну):

1. Положить на вершину стека первую из используемых глобальных переменных
    (`print`).
2. Положить на вершину стека первый аргумент функции (`x`, `print`).
3. Еще раз положить тот же аргумент на вершину стека (`x`, `x`, `print`).
4. Забрать с вершины стека два значения, перемножить их и положить результат
    на вершину стека (`x*x`, `print`).
5. Вызвать функцию, передав ей один позиционный аргумент.  Функции берут
    переметры со стека.  Один элемент с вершины стека — значение `x*x`.
    Следом за ним в стеке находится `print`, она и будет вызываемой функцией.
6. Убрать значение с вершины стека (стек пуст).
7. Положить на вершину стека константу `None` (`None`).
8. Вернуться в вызывающий код (`None`).  Значение на стеке будет результатом
    работы функции.

Отметим, что при вызове функции на стеке могут быть значения, поэтому «стек
пуст» следует понимать как «на стеке нет ничего сверх того, что было перед
вызовом функции».

Подробнее о виртуальной машине и байт-коде Python:

* <https://opensource.com/article/18/4/introduction-python-bytecode>
* <https://www.ics.uci.edu/~brgallar/week9_3.html>



# Лабораторная работа

Повторить пошаговую трансляцию в исполняемый файл и ее разбор для исходного
кода в соответствии с вариантом.  Необходимо представить в отчете:

1. Команды для вызова препроцессора, компилятора, ассемблера, компоновщика.
2. Строки препроцессированного файла, где упоминаются задействованные
    функции и константы (кроме 0 в `return 0`).
3. Таблица релокаций, таблица экспорта и ассемблерный листинг с указанием
    соответствия между записями в таблице релокаций и фрагментами объектного
    кода.
4. Информация о том, в каких стандартных библиотеках содержатся
    задействованные функции.

Варианты кода:

1. Печать числа π:

    ``` c
    #include <stdio.h>
    int main() {
        printf("pi = %g\n", 3.1415);
        return 0;
    }
    ```

2. Завершение с возвратом псевдослучайного числа:

    ``` c
    #include <stdlib.h>
    int main() {
        srand(42);
        return rand();
    ```

3. Печать переменной окружения `PATH`:

    ``` c
    #include <stdlib.h>
    int main() {
        puts(getenv("PATH"));
        return 0;
    ```

4. Возврат кода, соответствующего количеству параметров:

    ``` c
    #include <stdio.h>
    #include <stdlib.h>
    int main(int argc, char** argv) {
        return puts(itoa(argc - 1));
    }
    ```




# Контрольные вопросы

1. Перечислите фазы трансляции, указав их связи, входные и выходные данные.
2. В чем заключается работа препроцессора? Перечислите виды препроцессоров.
3. Какова задача компилятора? Опишите дополнительные функции,
    которые он может при этом выполнять.
4. Опишите работу компоновщика, данные, которыми он оперирует,
    их расположение в объектном файле.
5. На какой фазе трансляции применяются: а) настройки оптимизации, б) список
    систмных библиотек для подключения?
6. Чем отличается байт-код от машинного кода и от языка ассемблера?