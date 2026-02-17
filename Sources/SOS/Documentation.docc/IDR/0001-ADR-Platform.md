# ARM64 Plattform

Die Implementierung erfolgt primär für die ARM64 Plattform.

## Entscheidung

✅ ARM64 

## Optionen

✅ ARM64 - weil Entwicklung unter dieser Plattform stattfindet und damit statt Emulation eine Virtualisierung möglich wird. Zudem wird die Entwicklung der Betriebssystemebene (Kernel) durch den recht direkten Einsprung in den 64bit Modus begünstigt. Die LLM sind zudem gut auf die ARM64 Systeme trainiert, was eine Einarbeitung erleichtert. Nachteil ist, dass Fragmentierung der Hardware auch nicht vor dem Bootprozess halt macht.

❌ x86-64 - weil die Emulation der Plattform sehr langsame Testzyklen bedingt. Zudem muss erst über den 16bit zum 32bit in den 64bit Modus gelangt werden, bevor man zur eigentlichen Betriebssystemebene (Kernel) kommt. Vorteil ist, dass zahlreiche Tutorials und Bespiele existieren und die x86 Hardware recht standardisiert ist.

❌ RISC-V - weil die Emulation der Plattform sehr langsame Testzyklen bedingt.
