# Netxeon MINI M8S II (Amlogic S905X) — Optimization & Monitoring Guide

[![SoC](https://img.shields.io/badge/SoC-Amlogic%20S905X-orange.svg)]()
[![RAM](https://img.shields.io/badge/RAM-2GB%20DDR3-blue.svg)]()
[![OS](https://img.shields.io/badge/Android-6.0.1%20Marshmallow-green.svg)]()
[![Root](https://img.shields.io/badge/Root-SuperSU%20(su.d)-red.svg)]()

*Read this in [English](#english) | [Русский](#русский)*

---

<a name="english"></a>
## English

### Overview & Device Specifications
The **Netxeon MINI M8S II** is a compact Android TV box based on the **Amlogic S905X** SoC:
- **CPU:** Quad-Core ARM Cortex-A53 (up to 1.5 GHz)
- **Architecture:** 32-bit `armeabi-v7a` (Kernel 3.14.29)
- **GPU:** ARM Mali-450 Penta-Core
- **RAM:** 2 GB DDR3
- **Storage:** 8 GB eMMC
- **OS:** Android 6.0.1 Marshmallow (API 23)
- **Root:** Pre-rooted with SuperSU (`/system/xbin/su`, `/system/su.d/` daemon support)

While the hardware is capable of 4K H.265/VP9 decoding, the factory stock firmware suffers from severe software bottlenecks, memory starvation, and telemetry. This repository contains complete scripts and documentation to unlock smooth playback and real-time monitoring.

---

### Factory Firmware Issues
1. **Aggressive CPU Core Sleep:** The stock `hotplug` governor aggressively turns off CPU cores 1–3, leaving only core 0 active. Additionally, idle frequency drops to 100 MHz, creating jarring UI lags and frame stutter upon waking up.
2. **eMMC Disk I/O Latency:** Storage uses the standard `cfq` scheduler with a 2048 KB read-ahead queue, leading to high latency on random reads and sluggish app startup.
3. **RAM Starvation:** Outdated Google Play Services run continuous background sync attempts that fail, hogging **~500 MB of RAM** and triggering aggressive Android Low-Memory-Killer (LMK) app closures.
4. **Preinstalled Spyware/Backdoors:** The factory image includes **Adups FOTA** (`com.adups.fota.sysoper`), an infamous Chinese telemetry/backdoor module.
5. **The Fake 42°C Battery Temperature Trap:** The TV box has no battery. The Amlogic `healthd` daemon returns a dummy fallback value of 42.4°C. Basic system overlay tools read `BatteryManager.EXTRA_TEMPERATURE` and display a static, useless `42°C`.

---

### Applied Optimizations

#### 1. CPU & Governor Tuning
- **All 4 Cores Kept Online:** Cores 0, 1, 2, and 3 are forced online via `/sys/devices/system/cpu/cpu*/online`.
- **Interactive Governor:** Replaced `hotplug` with `interactive`.
- **Frequency Floor at 500 MHz:** Raised minimum frequency from 100 MHz to 500 MHz (`scaling_min_freq=500000`) to eliminate UI stutter when navigating menus.
- **Fast Ramp-up:** Set `hispeed_freq=1000000`, `go_hispeed_load=70`, and `io_is_busy=1` for immediate responsiveness during video buffering and app launches.

#### 2. Storage & Memory Tuning
- **Deadline I/O Scheduler:** Switched eMMC scheduler from `cfq` to `deadline`, reducing seek penalties.
- **Read-Ahead Queue:** Reduced `read_ahead_kb` from 2048 to 512 KB, cutting random I/O latency.
- **VFS Cache Pressure:** Tuned `vfs_cache_pressure=70`, `dirty_ratio=20`, and `dirty_background_ratio=5` to prevent sudden write stalls.

#### 3. Network Buffers for 4K / TorrServer Streaming
- Increased Linux socket buffers to **2 MB** (`net.core.rmem_max=2097152`, `wmem_max=2097152`, `tcp_rmem`, `tcp_wmem`).
- Prevents dropped TCP packets and buffering loops during high-bitrate video streaming and torrent downloads.

#### 4. Safe Debloat: Freeing ~500 MB RAM
Executing [`scripts/debloat.sh`](scripts/debloat.sh) disables:
- **Adups FOTA Spyware:** `com.adups.fota.sysoper`, `com.adups.fota`
- **Dead DroidLogic Services:** `com.droidlogic.otaupgrade`, `com.droidlogic.readlog`
- **Live Wallpapers & Screensavers:** `galaxy4`, `holospiral`, `phasebeam`, `noisefield`, `magicsmoke`, `phototable`
- **Google Play Services:** `com.google.android.gms`, `com.android.vending`, `gsf`, syncadapters.
- **Result:** RAM usage drops from ~790 MB down to **~450 MB**, leaving **~1.25 GB of free RAM** available for media players, Lampa, and TorrServer.

#### 5. Persistent Boot Script
All system tweaks are stored in `/system/su.d/01_performance.sh`. The SuperSU daemon automatically executes scripts in `/system/su.d/` with root privileges at every boot. It also persists `setprop service.adb.tcp.port 5555` to keep wireless ADB open across reboots.

---

### Hardware & Temperature Monitoring

#### Real SoC Temperature vs. Dummy Battery Temp
- **Dummy Battery Temp:** Any tool that displays 42°C is reading `/sys/class/power_supply/battery/temp`.
- **True Amlogic SoC Temperature:** Located at `/sys/class/thermal/thermal_zone0/temp` (values in millidegrees Celsius, e.g. `52000` = 52°C). Under normal idle/UI load, temperatures are around 50–55°C.

#### Recommended Monitoring Tools
1. **DevCheck (ARMv7 / 32-bit):**
   - Download the `armeabi-v7a` build (v5.46+ compatible with Android 6).
   - In DevCheck → **Sensors** (**Датчики**) → **Temperatures** (**Температуры**), tap `soc_thermal` and select **Set as Temperature 1** (**Температура 1**).
   - The dashboard and Floating Monitor will now display genuine real-time CPU thermal readings alongside frequencies of all 4 cores and RAM load.
2. **Cool Tool (`ds.cpuoverlay`):**
   - Lightweight floating overlay for real-time CPU% graph, free RAM, and network I/O.

---

### Quick Installation

Clone this repository and run the automated installer over ADB:
```bash
git clone https://github.com/groundsquirrel/mini-m8s-ii.git
cd mini-m8s-ii
chmod +x scripts/*.sh

# Connect to your TV box
adb connect <TV_BOX_IP>:5555

# Install all optimizations and debloat
./scripts/install_tweaks.sh
```

---

<a name="русский"></a>
## Русский

### Обзор и характеристики приставки
**Netxeon MINI M8S II** — компактная ТВ-приставка на базе чипа **Amlogic S905X**:
- **Процессор:** 4 ядра ARM Cortex-A53 (до 1.5 ГГц)
- **Архитектура:** 32-битная `armeabi-v7a` (Ядро Linux 3.14.29)
- **Видеоускоритель:** ARM Mali-450 Penta-Core
- **ОЗУ (RAM):** 2 ГБ DDR3
- **Накопитель:** 8 ГБ eMMC
- **ОС:** Android 6.0.1 Marshmallow (API 23)
- **Root-доступ:** Предустановлен SuperSU (`/system/xbin/su`, поддержка скриптов автозапуска `/system/su.d/`)

Несмотря на аппаратную поддержку 4K H.265/VP9, заводская прошивка страдает от программных ограничений ядра, дефицита оперативной памяти и фоновой телеметрии. В данном репозитории собраны скрипты и документация для полной оптимизации и мониторинга приставки.

---

### Проблемы заводской прошивки
1. **Агрессивный сон ядер CPU:** Режим `hotplug` по умолчанию отключает ядра 1–3, оставляя работать только ядро 0. Частота в простое падает до 100 МГц, вызывая микрофризы при нажатии кнопок пульта.
2. **Задержки памяти eMMC:** Планировщик `cfq` с буфером упреждающего чтения 2048 КБ создает высокую задержку при случайном чтении, замедляя запуск приложений.
3. **Нехватка оперативной памяти:** Устаревшие службы Google Play непрерывно пытаются выполнить фоновую синхронизацию, расходуя **~500 МБ ОЗУ** и провоцируя выгрузку видеоплееров системой Android Low Memory Killer.
4. **Предустановленный бэкдор:** В заводской прошивке присутствует модуль **Adups FOTA** (`com.adups.fota.sysoper`), отправляющий пользовательские данные на китайские серверы.
5. **Обман датчика батареи (ложные 42°C):** В ТВ-приставке нет физического аккумулятора. Системная служба `healthd` отдает жестко заданное значение 42.4°C. Стандартные виджеты читают температуру батареи и всегда показывают бесполезные статичные `42°C`.

---

### Проведенная оптимизация

#### 1. Тюнинг процессора и планировщика (Governor)
- **Все 4 активных ядра:** Ядра 0, 1, 2 и 3 принудительно включены через `/sys/devices/system/cpu/cpu*/online`.
- **Регулятор Interactive:** Планировщик переведен с `hotplug` на `interactive`.
- **Минимальная планка частоты 500 МГц:** Нижний порог частоты поднят со 100 до 500 МГц (`scaling_min_freq=500000`), устраняя подлагивания интерфейса при выходе из покоя.
- **Мгновенный разгон:** Настроены параметры `hispeed_freq=1000000`, `go_hispeed_load=70` и `io_is_busy=1` для плавного отклика при навигации и буферизации видео.

#### 2. Оптимизация накопителя eMMC и кэша
- **Планировщик Deadline:** Накопитель eMMC переведен на планировщик `deadline`, минимизирующий задержки чтения.
- **Буфер упреждающего чтения:** Значение `read_ahead_kb` снижено с 2048 до 512 КБ для ускорения случайного доступа.
- **Сброс страниц памяти:** Параметры ядра `vfs_cache_pressure=70`, `dirty_ratio=20` и `dirty_background_ratio=5` удерживают метаданные файлов в ОЗУ и предотвращают дисковые зависания.

#### 3. Сетевые буферы для 4K и TorrServer
- Системные буферы сокетов TCP увеличены до **2 МБ** (`net.core.rmem_max=2097152`, `wmem_max=2097152`, `tcp_rmem`, `tcp_wmem`).
- Устраняет прерывания видеопотока и повторную буферизацию при скачках битрейта в онлайн-кинотеатрах и торрент-стриминге.

#### 4. Debloat: Освобождение ~500 МБ RAM
Скрипт [`scripts/debloat.sh`](scripts/debloat.sh) безопасно отключает:
- **Шпионский бэкдор Adups:** `com.adups.fota.sysoper`, `com.adups.fota`
- **Неработающие службы DroidLogic:** `com.droidlogic.otaupgrade`, `com.droidlogic.readlog`
- **Фоновые живые обои и заставки:** `galaxy4`, `holospiral`, `phasebeam`, `noisefield`, `magicsmoke`, `phototable`
- **Сервисы Google Play:** `com.google.android.gms`, `com.android.vending`, `gsf`, адаптеры контактов/календаря.
- **Результат:** Занятая память падает с ~790 МБ до **~450 МБ**, оставляя **~1.25 ГБ свободной оперативной памяти** для плееров, Lampa и TorrServer.

#### 5. Автозапуск при включении приставки
Скрипт помещен в `/system/su.d/01_performance.sh`. Служба SuperSU `daemonsu` автоматически выполняет файлы из `/system/su.d/` с правами root при каждой загрузке. Скрипт также фиксирует сетевой порт ADB 5555 (`service.adb.tcp.port 5555`), чтобы не терять удаленный доступ после перезагрузки.

---

### Мониторинг процессора и реальной температуры

#### Реальная температура SoC vs. Заглушка батареи
- **Ложные 42°C:** Любые утилиты, показывающие 42°C, обращаются к `/sys/class/power_supply/battery/temp`.
- **Истинный датчик Amlogic SoC:** Находится по адресу `/sys/class/thermal/thermal_zone0/temp` (значение в миллиградусах Цельсия, например `52000` = 52°C). В нормальном режиме температура чипа составляет 50–55°C.

#### Настройка утилит мониторинга
1. **DevCheck (ARMv7 / 32-bit):**
   - Установите сборку `armeabi-v7a` (версия 5.46+, поддерживающая Android 6).
   - В DevCheck перейдите в **Датчики** → **Температуры**, нажмите на строку `soc_thermal` и выберите **Установить как Температура 1**.
   - Теперь на главном экране и в плавающем мониторе отображается реальная температура ядра процессора, частота всех 4 ядер и загрузка памяти.
2. **Cool Tool (`ds.cpuoverlay`):**
   - Компактный плавающий индикатор поверх всех окон с графиком нагрузки CPU, объемом свободной памяти и сетевой активностью.

---

### Быстрая установка через ADB

```bash
git clone https://github.com/groundsquirrel/mini-m8s-ii.git
cd mini-m8s-ii
chmod +x scripts/*.sh

# Подключение к приставке
adb connect <IP_АДРЕС_ПРИСТАВКИ>:5555

# Установка всех твиков и отключение служб
./scripts/install_tweaks.sh
```
