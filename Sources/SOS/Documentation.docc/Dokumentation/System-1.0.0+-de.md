# SOS-Entwicklung 1.0.0+

Überblick über Ziele und Inhalte der Versionen 1.0 bis 1.x

## 1.0.0

**fast ein BareMetal (qemu) minimaler Embedded Swift ARM64 kernel**

* **Swift over Assembler** - was in Swift implementierbar ist, wird in Swift gemacht
* **qemu** lauffähiger Kernel in Embedded Swift mit minimalem Assembleranteil
* **ARM64** Kernel, da *zukunftssicher*, *virtualisierbar statt nur emulierbar* auf Entwicklerrechner und *einfacherer Bootprozess*
* **UART** Ausgabe sowohl vom Assemblerteil als auch vom Swift Kernel
* **Shutdown** des Systems von Swiftseite
* *SwiftPackageIndex* Aufnahme
* *Dokumentation*

## 1.1.0

* Der **Devicetree blob** wird nunmehr von Assembler bis Swift durchgereicht.
* Nur der **Core 0 startet den Kernel**, auch bei Start mit QEMU und nicht nur bei Raspberry Pi 4
* Der Link Prozess wurde korrigiert.
* *SwiftPackageIndex* hat einen Debug bei der SPM Verarbeitung, da dort nicht mit Swiftly gearbeitet wird
* *Dokumentation*
* *Design Entscheidungen*

## 1.2.0

* Der **Devicetree blob** wird (ohne Heap) geparst
* Der **verfügbare RAM** ist bekannt
* Swift wird nun als **Position Independent Executable (PIE)** gebaut
