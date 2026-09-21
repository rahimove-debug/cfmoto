(function () {
  "use strict";

  var LOAD_POINTS = [75, 115, 150, 190];
  var POUNDS_PER_KILOGRAM = 2.2046226218;

  var MODELS = {
    "1000mt-x": {
      label: "1000MT-X",
      direction: "clockwise-stop",
      units: { fp: "mm", fc: "click", fr: "click", rp: "click", rc: "click", rr: "click" },
      road: [
        { fp: 11.5, fc: 10, fr: 10, rp: 12, rc: 10, rr: 10 },
        { fp: 9.5, fc: 10, fr: 10, rp: 10, rc: 8, rr: 7 },
        { fp: 8.5, fc: 7, fr: 7, rp: 8, rc: 6, rr: 5 },
        { fp: 5.5, fc: 5, fr: 5, rp: 6, rc: 4, rr: 3 }
      ],
      rough: { fp: 11.5, fc: 10, fr: 7, rp: 12, rc: 6, rr: 7 }
    },
    "800mt-x": {
      label: "800MT-X",
      direction: "counterclockwise-stop",
      units: { fp: "turn", fc: "click", fr: "click", rp: "turn", rc: "click", rr: "click" },
      road: [
        { fp: 4, fc: 10, fr: 10, rp: 3, rc: 8, rr: 12 },
        { fp: 4, fc: 10, fr: 10, rp: 5, rc: 10, rr: 15 },
        { fp: 5, fc: 13, fr: 13, rp: 6, rc: 12, rr: 17 },
        { fp: 6, fc: 15, fr: 15, rp: 8, rc: 14, rr: 19 }
      ],
      rough: { fp: 4, fc: 10, fr: 13, rp: 3, rc: 12, rr: 15 }
    },
    "800mt-sport": {
      label: "800MT SPORT",
      sourceKey: "800mt",
      direction: "counterclockwise-stop",
      units: { fp: "turn", fc: "click", fr: "click", rp: "turn", rc: null, rr: "click" },
      road: [
        { fp: 4, fc: 10, fr: 10, rp: 3, rc: null, rr: 10 },
        { fp: 4, fc: 10, fr: 10, rp: 5, rc: null, rr: 15 },
        { fp: 5, fc: 13, fr: 13, rp: 6, rc: null, rr: 17 },
        { fp: 6, fc: 15, fr: 15, rp: 7, rc: null, rr: 19 }
      ]
    },
    "800mt-explore": {
      label: "800MT EXPLORE",
      sourceKey: "800mt",
      direction: "counterclockwise-stop",
      units: { fp: "turn", fc: "click", fr: "click", rp: "turn", rc: null, rr: "click" },
      road: [
        { fp: 4, fc: 10, fr: 10, rp: 3, rc: null, rr: 10 },
        { fp: 4, fc: 10, fr: 10, rp: 5, rc: null, rr: 15 },
        { fp: 5, fc: 13, fr: 13, rp: 6, rc: null, rr: 17 },
        { fp: 6, fc: 15, fr: 15, rp: 7, rc: null, rr: 19 }
      ]
    },
    "700mt": {
      label: "700MT",
      direction: "mixed",
      units: { fp: null, fc: "click", fr: "click", rp: "turn", rc: null, rr: "click" },
      road: [
        { fp: null, fc: 10, fr: 10, rp: 6, rc: null, rr: 7 },
        { fp: null, fc: 10, fr: 10, rp: 9, rc: null, rr: 4 },
        { fp: null, fc: 14, fr: 14, rp: 10, rc: null, rr: 3 },
        { fp: null, fc: 16, fr: 16, rp: 12, rc: null, rr: 1 }
      ],
      rough: { fp: null, fc: 8, fr: 8, rp: 6, rc: null, rr: 8 }
    },
    "450mt": {
      label: "450MT",
      special: true,
      direction: "manual",
      units: { fp: "mm", fc: null, fr: "click", rp: "custom", rc: null, rr: "click" }
    }
  };

  var COPY = {
    az: {
      eyebrow: "CFMOTO texniki aləti",
      title: "Asqı sazlamasını hesablayın",
      intro: "Modeli və real yükü seçin. Kalkulyator kitabçadakı yük nöqtələri arasında hesablayaraq başlanğıc sazlamasını göstərir.",
      model: "Model",
      chooseModel: "Motosikleti seçin",
      mode: "Sürüş rejimi",
      road: "Yol",
      rough: "Yolsuzluq",
      roughUnavailable: "Bu model üçün ayrıca rəsmi yolsuzluq sətri yoxdur",
      scenario: "Yük ssenarisi",
      solo: "Tək sürücü",
      luggage: "Sürücü + baqaj",
      threeCases: "Sürücü + 3 çanta",
      passenger: "Sürücü + sərnişin",
      passengerLuggage: "Sərnişin + baqaj",
      unit: "Çəki vahidi",
      weights: "Çəkilər",
      riderWeight: "Sürücü",
      passengerWeight: "Sərnişin",
      luggageWeight: "Baqaj",
      seat: "450MT oturacaq sazlaması",
      standardSeat: "Standart",
      loweredSeat: "Alçaldılmış",
      seatHelp: "450MT nəticəsi sürücü çəkisinə görə interpolasiya edilmir; oturacaq və baqaj vəziyyətinə görə kitabça sazlaması göstərilir.",
      resultEyebrow: "Hesablanmış başlanğıc nöqtəsi",
      resultTitle: "Tövsiyə olunan sazlama",
      totalLoad: "Ümumi yük",
      fixedSetting: "Sabit kitabça sazlaması",
      front: "Ön amortizator",
      rear: "Arxa amortizator",
      preload: "Yay ön gərginliyi",
      compression: "Sıxılma",
      rebound: "Geri açılma",
      notAdjustable: "Tənzimlənmir",
      factorySetting: "Zavod sazlaması",
      noRearChange: "Dəyişiklik yoxdur",
      springLength204: "204 mm yay uzunluğu",
      plus4Turns: "Zavod sazlamasından +4 dövr",
      plus6Turns: "Zavod sazlamasından +6 dövr",
      visibleSleeve12: "12 mm görünən hissə",
      click: "klik",
      turn: "dövr",
      mm: "mm",
      details: "Hesablamanın izahı",
      interpolation: "%1–%2 kq sətirləri arasında %3% interpolasiya edildi.",
      exactPoint: "%1 kq kitabça sətri birbaşa tətbiq edildi.",
      clampedLow: "Yük 75 kq-dan aşağıdır; ən yaxın 75 kq kitabça sətri tətbiq edildi.",
      clampedHigh: "Yük 190 kq-dan yuxarıdır; ən yaxın 190 kq kitabça sətri tətbiq edildi. Bu, motosikletin icazə verilən yükünü təsdiqləmir.",
      roughDetail: "Model üçün kitabçada ayrıca göstərilən yolsuzluq sətri tətbiq edildi; yük interpolasiyası aparılmadı.",
      mt450DetailStandard: "450MT üçün standart oturacaq və %1 vəziyyətinə uyğun kitabça sazlaması tətbiq edildi.",
      mt450DetailLowered: "450MT üçün alçaldılmış oturacaq və %1 vəziyyətinə uyğun kitabça sazlaması tətbiq edildi.",
      withoutLuggage: "baqajsız",
      withLuggage: "3 çanta ilə",
      safetyTitle: "Təhlükəsizlik qeydi",
      safety: "Bu nəticə yalnız başlanğıc sazlamasıdır. Tənzimləmədən əvvəl modelin istifadəçi kitabçasını yoxlayın, tənzimləyicini zorlamayın və dəyişiklikdən sonra təhlükəsiz ərazidə sınaq sürüşü edin.",
      countNote: "Klik və dövrləri yalnız kitabçada göstərilən başlanğıc nöqtəsindən sayın. Şin təzyiqi və icazə verilən yük bu kalkulyatorla hesablanmır.",
      roughWarning: "Yolsuzluq sazlamasını asfalt üçün avtomatik uyğun hesab etməyin; yol şəraiti dəyişdikdə kitabça sazlamasına qayıdın.",
      source: "Mənbə sənədi",
      copy: "Nəticəni kopyala",
      print: "Çap et",
      copied: "Nəticə kopyalandı.",
      copyFailed: "Avtomatik kopyalama alınmadı. Nəticəni əl ilə seçə bilərsiniz.",
      reset: "İlkin vəziyyət",
      copyHeading: "CFMOTO asqı sazlaması",
      weightNotUsed450: "450MT üçün kitabçada çəkiyə görə cədvəl verilmədiyindən rəqəmsal yük hesablaması tətbiq edilmir.",
      roughFixedHelp: "Yolsuzluq nəticəsi kitabçada yalnız 75 kq-lıq tək sürücü üçün verilən sabit sətirdir; fərqli yük üçün interpolasiya edilmir.",
      direction: "Sayma istiqaməti",
      directionClockwise: "Tam saat istiqamətində yüngül dayanmaya qədər bağlayın, sonra saat əqrəbinin əksinə sayın.",
      directionCounterclockwise: "Tam saat əqrəbinin əksinə yüngül dayanmaya qədər açın, sonra saat istiqamətində sayın.",
      directionMixed: "Ön amortizatoru əks istiqamətdə son nöqtədən saat istiqamətinə sayın; arxa geri açılmanı saat istiqamətində son nöqtədən əksinə sayın.",
      directionManual: "450MT tənzimləyicilərini mənbə kitabçadakı göstərişə uyğun sayın.",
      invalidWeight: "Çəkini mənfi olmayan rəqəmlə daxil edin."
    },
    ru: {
      eyebrow: "Технический инструмент CFMOTO",
      title: "Рассчитайте настройку подвески",
      intro: "Выберите модель и фактическую нагрузку. Калькулятор вычисляет стартовую настройку между точками нагрузки из руководства.",
      model: "Модель",
      chooseModel: "Выберите мотоцикл",
      mode: "Режим езды",
      road: "Дорога",
      rough: "Бездорожье",
      roughUnavailable: "Для этой модели нет отдельной официальной строки для бездорожья",
      scenario: "Сценарий нагрузки",
      solo: "Только водитель",
      luggage: "Водитель + багаж",
      threeCases: "Водитель + 3 кофра",
      passenger: "Водитель + пассажир",
      passengerLuggage: "Пассажир + багаж",
      unit: "Единица веса",
      weights: "Вес",
      riderWeight: "Водитель",
      passengerWeight: "Пассажир",
      luggageWeight: "Багаж",
      seat: "Настройка сиденья 450MT",
      standardSeat: "Стандартное",
      loweredSeat: "Заниженное",
      seatHelp: "Результат 450MT не интерполируется по весу водителя; показывается настройка руководства для положения сиденья и наличия багажа.",
      resultEyebrow: "Рассчитанная стартовая точка",
      resultTitle: "Рекомендуемая настройка",
      totalLoad: "Общая нагрузка",
      fixedSetting: "Фиксированная настройка руководства",
      front: "Передняя подвеска",
      rear: "Задняя подвеска",
      preload: "Преднатяг пружины",
      compression: "Сжатие",
      rebound: "Отбой",
      notAdjustable: "Не регулируется",
      factorySetting: "Заводская настройка",
      noRearChange: "Без изменения",
      springLength204: "Длина пружины 204 мм",
      plus4Turns: "+4 оборота от заводской настройки",
      plus6Turns: "+6 оборотов от заводской настройки",
      visibleSleeve12: "Видимая часть 12 мм",
      click: "щелч.",
      turn: "обор.",
      mm: "мм",
      details: "Как выполнен расчёт",
      interpolation: "Выполнена интерполяция %3% между строками %1 и %2 кг.",
      exactPoint: "Напрямую применена строка руководства для %1 кг.",
      clampedLow: "Нагрузка ниже 75 кг; применена ближайшая строка руководства для 75 кг.",
      clampedHigh: "Нагрузка выше 190 кг; применена ближайшая строка руководства для 190 кг. Это не подтверждает допустимую нагрузку мотоцикла.",
      roughDetail: "Применена отдельная строка руководства для бездорожья; интерполяция по нагрузке не выполнялась.",
      mt450DetailStandard: "Для 450MT применена настройка руководства для стандартного сиденья и режима «%1».",
      mt450DetailLowered: "Для 450MT применена настройка руководства для заниженного сиденья и режима «%1».",
      withoutLuggage: "без багажа",
      withLuggage: "с 3 кофрами",
      safetyTitle: "Важно для безопасности",
      safety: "Результат является только стартовой настройкой. Перед регулировкой проверьте руководство модели, не прикладывайте чрезмерное усилие к регуляторам и после изменений выполните пробную поездку в безопасном месте.",
      countNote: "Считайте щелчки и обороты только от начальной точки, указанной в руководстве. Давление в шинах и допустимая нагрузка этим калькулятором не рассчитываются.",
      roughWarning: "Не считайте настройку для бездорожья автоматически подходящей для асфальта; при смене покрытия вернитесь к настройке руководства.",
      source: "Документ-источник",
      copy: "Копировать результат",
      print: "Печать",
      copied: "Результат скопирован.",
      copyFailed: "Не удалось скопировать автоматически. Результат можно выделить вручную.",
      reset: "Сбросить",
      copyHeading: "Настройка подвески CFMOTO",
      weightNotUsed450: "Для 450MT в руководстве нет таблицы по весу, поэтому числовой расчёт нагрузки не применяется.",
      roughFixedHelp: "Результат для бездорожья — фиксированная строка руководства только для одного водителя массой 75 кг; для другой нагрузки интерполяция не выполняется.",
      direction: "Направление отсчёта",
      directionClockwise: "Закройте регулятор по часовой стрелке до лёгкого упора, затем считайте против часовой стрелки.",
      directionCounterclockwise: "Откройте регулятор против часовой стрелки до лёгкого упора, затем считайте по часовой стрелке.",
      directionMixed: "Переднюю подвеску считайте по часовой стрелке от крайнего положения против часовой; задний отбой — против часовой стрелки от крайнего положения по часовой.",
      directionManual: "Для 450MT считайте регулировки по инструкции в исходном руководстве.",
      invalidWeight: "Введите неотрицательное числовое значение веса."
    }
  };

  var SCENARIOS = {
    solo: { passenger: false, luggage: false },
    luggage: { passenger: false, luggage: true },
    passenger: { passenger: true, luggage: false },
    "passenger-luggage": { passenger: true, luggage: true }
  };

  var instances = new WeakMap();

  function escapeHtml(value) {
    return String(value)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#039;");
  }

  function languageFor(root) {
    var requested = (root.getAttribute("data-language") || document.documentElement.lang || "az").toLowerCase();
    return requested.indexOf("ru") === 0 ? "ru" : "az";
  }

  function t(state, key) {
    return COPY[state.language][key] || COPY.az[key] || key;
  }

  function template(state) {
    var text = COPY[state.language];
    var modelOptions = Object.keys(MODELS).map(function (id) {
      return '<option value="' + escapeHtml(id) + '">' + escapeHtml(MODELS[id].label) + "</option>";
    }).join("");

    return '' +
      '<section class="cfsc-widget" aria-labelledby="' + state.ids.title + '">' +
        '<header class="cfsc-intro">' +
          '<p class="cfsc-eyebrow">' + escapeHtml(text.eyebrow) + '</p>' +
          '<h2 id="' + state.ids.title + '">' + escapeHtml(text.title) + '</h2>' +
          '<p>' + escapeHtml(text.intro) + '</p>' +
        '</header>' +
        '<div class="cfsc-layout">' +
          '<form class="cfsc-panel cfsc-controls" data-cfsc-form novalidate>' +
            '<div class="cfsc-control-block">' +
              '<label class="cfsc-label" for="' + state.ids.model + '"><span>01</span>' + escapeHtml(text.model) + '</label>' +
              '<select class="cfsc-select" id="' + state.ids.model + '" data-cfsc-model aria-describedby="' + state.ids.modelHelp + '">' + modelOptions + '</select>' +
              '<p class="cfsc-help" id="' + state.ids.modelHelp + '">' + escapeHtml(text.chooseModel) + '</p>' +
            '</div>' +
            '<fieldset class="cfsc-control-block">' +
              '<legend class="cfsc-label"><span>02</span>' + escapeHtml(text.mode) + '</legend>' +
              '<div class="cfsc-segments cfsc-segments-two" data-cfsc-mode-group>' +
                segmentButton("mode", "road", text.road) +
                segmentButton("mode", "rough", text.rough) +
              '</div>' +
              '<p class="cfsc-help" data-cfsc-mode-help></p>' +
            '</fieldset>' +
            '<fieldset class="cfsc-control-block" data-cfsc-scenario-block>' +
              '<legend class="cfsc-label"><span>03</span>' + escapeHtml(text.scenario) + '</legend>' +
              '<div class="cfsc-segments cfsc-scenarios" data-cfsc-scenario-group>' +
                segmentButton("scenario", "solo", text.solo) +
                segmentButton("scenario", "luggage", text.luggage) +
                segmentButton("scenario", "passenger", text.passenger) +
                segmentButton("scenario", "passenger-luggage", text.passengerLuggage) +
              '</div>' +
            '</fieldset>' +
            '<fieldset class="cfsc-control-block" data-cfsc-seat-block hidden>' +
              '<legend class="cfsc-label"><span>04</span>' + escapeHtml(text.seat) + '</legend>' +
              '<div class="cfsc-segments cfsc-segments-two">' +
                segmentButton("seat", "standard", text.standardSeat) +
                segmentButton("seat", "lowered", text.loweredSeat) +
              '</div>' +
              '<p class="cfsc-help">' + escapeHtml(text.seatHelp) + '</p>' +
            '</fieldset>' +
            '<fieldset class="cfsc-control-block" data-cfsc-weight-block>' +
              '<legend class="cfsc-label"><span data-cfsc-weight-step>04</span>' + escapeHtml(text.weights) + '</legend>' +
              '<div class="cfsc-unit-row">' +
                '<span>' + escapeHtml(text.unit) + '</span>' +
                '<div class="cfsc-unit-toggle" role="group" aria-label="' + escapeHtml(text.unit) + '">' +
                  segmentButton("unit", "kg", "kg") +
                  segmentButton("unit", "lb", "lb") +
                '</div>' +
              '</div>' +
              '<div class="cfsc-weight-grid">' +
                weightInput(state, "rider", text.riderWeight) +
                weightInput(state, "passenger", text.passengerWeight) +
                weightInput(state, "luggage", text.luggageWeight) +
              '</div>' +
              '<p class="cfsc-validation" data-cfsc-validation role="alert" hidden></p>' +
            '</fieldset>' +
            '<p class="cfsc-special-help" data-cfsc-special-help hidden>' + escapeHtml(text.weightNotUsed450) + '</p>' +
            '<p class="cfsc-special-help" data-cfsc-rough-fixed-help hidden>' + escapeHtml(text.roughFixedHelp) + '</p>' +
            '<button type="button" class="cfsc-reset" data-cfsc-action="reset">' + escapeHtml(text.reset) + '</button>' +
          '</form>' +
          '<aside class="cfsc-panel cfsc-results" aria-labelledby="' + state.ids.resultTitle + '">' +
            '<div class="cfsc-result-head">' +
              '<div><p class="cfsc-eyebrow">' + escapeHtml(text.resultEyebrow) + '</p><h3 id="' + state.ids.resultTitle + '">' + escapeHtml(text.resultTitle) + '</h3></div>' +
              '<p class="cfsc-load"><span data-cfsc-load-label>' + escapeHtml(text.totalLoad) + '</span><strong data-cfsc-load>75 kg</strong></p>' +
            '</div>' +
            '<div class="cfsc-result-live" data-cfsc-results aria-live="polite" aria-atomic="true"></div>' +
            '<details class="cfsc-detail"><summary>' + escapeHtml(text.details) + '</summary><p data-cfsc-detail></p></details>' +
            '<div class="cfsc-safety" role="note"><strong>' + escapeHtml(text.safetyTitle) + '</strong><p>' + escapeHtml(text.safety) + '</p><p>' + escapeHtml(text.countNote) + '</p><p data-cfsc-rough-warning hidden>' + escapeHtml(text.roughWarning) + '</p></div>' +
            '<a class="cfsc-source" data-cfsc-source target="_blank" rel="noopener noreferrer" hidden>' + escapeHtml(text.source) + '<span aria-hidden="true">↗</span></a>' +
            '<div class="cfsc-actions">' +
              '<button type="button" data-cfsc-action="copy">' + copyIcon() + '<span>' + escapeHtml(text.copy) + '</span></button>' +
              '<button type="button" data-cfsc-action="print">' + printIcon() + '<span>' + escapeHtml(text.print) + '</span></button>' +
            '</div>' +
            '<p class="cfsc-status" data-cfsc-status role="status" aria-live="polite"></p>' +
          '</aside>' +
        '</div>' +
      '</section>';
  }

  function segmentButton(group, value, label) {
    return '<button type="button" data-cfsc-' + group + '="' + escapeHtml(value) + '" aria-pressed="false">' + escapeHtml(label) + '</button>';
  }

  function weightInput(state, name, label) {
    var id = state.ids[name];
    return '<label class="cfsc-weight-field" data-cfsc-weight-row="' + name + '" for="' + id + '"><span>' + escapeHtml(label) + '</span><span class="cfsc-input-wrap"><input id="' + id + '" data-cfsc-weight="' + name + '" type="number" min="0" step="0.5" inputmode="decimal" autocomplete="off"><b data-cfsc-unit-label>kg</b></span></label>';
  }

  function copyIcon() {
    return '<svg viewBox="0 0 24 24" aria-hidden="true"><rect x="8" y="8" width="11" height="11" rx="2"></rect><path d="M16 8V6a2 2 0 0 0-2-2H6a2 2 0 0 0-2 2v8a2 2 0 0 0 2 2h2"></path></svg>';
  }

  function printIcon() {
    return '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M7 8V4h10v4M7 17H5a2 2 0 0 1-2-2v-4a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2v4a2 2 0 0 1-2 2h-2"></path><path d="M7 14h10v6H7z"></path></svg>';
  }

  function defaultState(root, index) {
    var initialModel = root.getAttribute("data-initial-model") || "800mt-x";
    if (!MODELS[initialModel]) initialModel = "800mt-x";
    var initialMode = root.getAttribute("data-initial-mode") === "rough" ? "rough" : "road";
    if (!MODELS[initialModel].rough) initialMode = "road";
    var prefix = "cfsc-" + (index + 1) + "-";
    return {
      root: root,
      language: languageFor(root),
      model: initialModel,
      mode: initialMode,
      scenario: "solo",
      unit: "kg",
      seat: "standard",
      weightsKg: { rider: 75, passenger: 75, luggage: 40 },
      ids: {
        title: prefix + "title",
        resultTitle: prefix + "result-title",
        model: prefix + "model",
        modelHelp: prefix + "model-help",
        rider: prefix + "rider",
        passenger: prefix + "passenger",
        luggage: prefix + "luggage"
      },
      lastResult: null
    };
  }

  function init(root, index) {
    if (!root || root.getAttribute("data-cfsc-ready") === "true") return instances.get(root);
    var state = defaultState(root, index || 0);
    root.innerHTML = template(state);
    root.setAttribute("data-cfsc-ready", "true");
    root.setAttribute("data-cfsc-language", state.language);
    instances.set(root, state);
    bind(state);
    sync(state);
    return state;
  }

  function bind(state) {
    state.root.addEventListener("click", function (event) {
      var button = event.target.closest("button");
      if (!button || !state.root.contains(button) || button.disabled) return;

      if (button.hasAttribute("data-cfsc-mode")) {
        state.mode = button.getAttribute("data-cfsc-mode");
        sync(state);
      } else if (button.hasAttribute("data-cfsc-scenario")) {
        chooseScenario(state, button.getAttribute("data-cfsc-scenario"));
        sync(state);
      } else if (button.hasAttribute("data-cfsc-unit")) {
        state.unit = button.getAttribute("data-cfsc-unit");
        sync(state);
      } else if (button.hasAttribute("data-cfsc-seat")) {
        state.seat = button.getAttribute("data-cfsc-seat");
        sync(state);
      } else if (button.getAttribute("data-cfsc-action") === "reset") {
        resetState(state);
        sync(state);
      } else if (button.getAttribute("data-cfsc-action") === "copy") {
        copyResult(state);
      } else if (button.getAttribute("data-cfsc-action") === "print") {
        printResult(state);
      }
    });

    state.root.querySelector("[data-cfsc-model]").addEventListener("change", function (event) {
      if (!MODELS[event.target.value]) return;
      state.model = event.target.value;
      if (!MODELS[state.model].rough) state.mode = "road";
      if (MODELS[state.model].special && (state.scenario === "passenger" || state.scenario === "passenger-luggage")) {
        state.scenario = "solo";
      }
      sync(state);
    });

    state.root.querySelectorAll("[data-cfsc-weight]").forEach(function (input) {
      input.addEventListener("input", function () {
        var value = Number(input.value);
        var validation = state.root.querySelector("[data-cfsc-validation]");
        if (!Number.isFinite(value) || value < 0) {
          validation.textContent = t(state, "invalidWeight");
          validation.hidden = false;
          input.setAttribute("aria-invalid", "true");
          return;
        }
        validation.hidden = true;
        input.removeAttribute("aria-invalid");
        state.weightsKg[input.getAttribute("data-cfsc-weight")] = state.unit === "lb" ? value / POUNDS_PER_KILOGRAM : value;
        renderResults(state);
      });
    });
  }

  function chooseScenario(state, scenario) {
    if (!SCENARIOS[scenario]) return;
    if (MODELS[state.model].special && (scenario === "passenger" || scenario === "passenger-luggage")) return;
    state.scenario = scenario;
    if (SCENARIOS[scenario].passenger && state.weightsKg.passenger === 0) state.weightsKg.passenger = 75;
    if (SCENARIOS[scenario].luggage && state.weightsKg.luggage === 0) state.weightsKg.luggage = 40;
  }

  function resetState(state) {
    state.model = state.root.getAttribute("data-initial-model") || "800mt-x";
    if (!MODELS[state.model]) state.model = "800mt-x";
    state.mode = state.root.getAttribute("data-initial-mode") === "rough" && MODELS[state.model].rough ? "rough" : "road";
    state.scenario = "solo";
    state.unit = "kg";
    state.seat = "standard";
    state.weightsKg = { rider: 75, passenger: 75, luggage: 40 };
    var status = state.root.querySelector("[data-cfsc-status]");
    if (status) status.textContent = "";
  }

  function sync(state) {
    var root = state.root;
    var model = MODELS[state.model];
    root.querySelector("[data-cfsc-model]").value = state.model;

    root.querySelectorAll("[data-cfsc-mode]").forEach(function (button) {
      var value = button.getAttribute("data-cfsc-mode");
      var unavailable = value === "rough" && !model.rough;
      button.disabled = unavailable;
      button.setAttribute("aria-pressed", String(value === state.mode));
      if (unavailable) button.title = t(state, "roughUnavailable");
      else button.removeAttribute("title");
    });
    var modeHelp = root.querySelector("[data-cfsc-mode-help]");
    modeHelp.textContent = !model.rough ? t(state, "roughUnavailable") : "";
    modeHelp.hidden = Boolean(model.rough);

    root.querySelectorAll("[data-cfsc-scenario]").forEach(function (button) {
      var value = button.getAttribute("data-cfsc-scenario");
      var passengerChoice = value === "passenger" || value === "passenger-luggage";
      button.disabled = Boolean(model.special && passengerChoice);
      button.hidden = Boolean(model.special && passengerChoice);
      if (value === "luggage") button.textContent = t(state, model.special ? "threeCases" : "luggage");
      button.setAttribute("aria-pressed", String(value === state.scenario));
    });

    root.querySelectorAll("[data-cfsc-unit]").forEach(function (button) {
      button.setAttribute("aria-pressed", String(button.getAttribute("data-cfsc-unit") === state.unit));
    });
    root.querySelectorAll("[data-cfsc-seat]").forEach(function (button) {
      button.setAttribute("aria-pressed", String(button.getAttribute("data-cfsc-seat") === state.seat));
    });

    root.querySelector("[data-cfsc-seat-block]").hidden = !model.special;
    var roughFixed = state.mode === "rough" && Boolean(model.rough);
    root.querySelector("[data-cfsc-scenario-block]").hidden = roughFixed;
    root.querySelector("[data-cfsc-weight-block]").hidden = Boolean(model.special || roughFixed);
    root.querySelector("[data-cfsc-special-help]").hidden = !model.special;
    root.querySelector("[data-cfsc-rough-fixed-help]").hidden = !roughFixed;

    var scenario = SCENARIOS[state.scenario];
    root.querySelector('[data-cfsc-weight-row="passenger"]').hidden = !scenario.passenger;
    root.querySelector('[data-cfsc-weight-row="luggage"]').hidden = !scenario.luggage;

    root.querySelectorAll("[data-cfsc-weight]").forEach(function (input) {
      var name = input.getAttribute("data-cfsc-weight");
      var displayValue = state.unit === "lb" ? state.weightsKg[name] * POUNDS_PER_KILOGRAM : state.weightsKg[name];
      input.value = formatInput(displayValue);
    });
    root.querySelectorAll("[data-cfsc-unit-label]").forEach(function (label) {
      label.textContent = state.unit;
    });

    updateSource(state);
    renderResults(state);
  }

  function formatInput(value) {
    return String(Math.round(value * 10) / 10);
  }

  function updateSource(state) {
    var source = state.root.querySelector("[data-cfsc-source]");
    var model = MODELS[state.model];
    var url = state.root.getAttribute("data-source-" + (model.sourceKey || state.model));
    if (url && /^https?:\/\//i.test(url)) {
      source.href = url;
      source.hidden = false;
    } else {
      source.removeAttribute("href");
      source.hidden = true;
    }
  }

  function scenarioLoadKg(state) {
    var scenario = SCENARIOS[state.scenario];
    return state.weightsKg.rider + (scenario.passenger ? state.weightsKg.passenger : 0) + (scenario.luggage ? state.weightsKg.luggage : 0);
  }

  function interpolate(model, loadKg) {
    var lowerIndex = 0;
    var upperIndex = 0;
    var ratio = 0;
    var detailType = "exact";

    if (loadKg <= LOAD_POINTS[0]) {
      detailType = loadKg < LOAD_POINTS[0] ? "low" : "exact";
    } else if (loadKg >= LOAD_POINTS[LOAD_POINTS.length - 1]) {
      lowerIndex = upperIndex = LOAD_POINTS.length - 1;
      detailType = loadKg > LOAD_POINTS[LOAD_POINTS.length - 1] ? "high" : "exact";
    } else {
      for (var i = 0; i < LOAD_POINTS.length - 1; i += 1) {
        if (loadKg >= LOAD_POINTS[i] && loadKg <= LOAD_POINTS[i + 1]) {
          lowerIndex = i;
          upperIndex = i + 1;
          ratio = (loadKg - LOAD_POINTS[i]) / (LOAD_POINTS[i + 1] - LOAD_POINTS[i]);
          detailType = ratio === 0 ? "exact" : (ratio === 1 ? "exact-upper" : "between");
          break;
        }
      }
    }

    var settings = {};
    Object.keys(model.units).forEach(function (key) {
      var low = model.road[lowerIndex][key];
      var high = model.road[upperIndex][key];
      if (low === null || high === null) settings[key] = null;
      else settings[key] = roundSetting(low + ((high - low) * ratio), model.units[key]);
    });

    return {
      settings: settings,
      detailType: detailType,
      lower: LOAD_POINTS[lowerIndex],
      upper: LOAD_POINTS[upperIndex],
      ratio: ratio
    };
  }

  function roundSetting(value, unit) {
    if (unit === "click") return Math.floor(value + 0.5);
    if (unit === "turn" || unit === "mm") return Math.floor((value * 2) + 0.5) / 2;
    return value;
  }

  function calculate(state) {
    var model = MODELS[state.model];
    if (model.special) return calculate450(state);

    var loadKg = scenarioLoadKg(state);
    if (state.mode === "rough" && model.rough) {
      return {
        settings: model.rough,
        loadKg: null,
        detail: t(state, "roughDetail"),
        fixed: true,
        rough: true
      };
    }

    var result = interpolate(model, loadKg);
    var detail;
    if (result.detailType === "low") detail = t(state, "clampedLow");
    else if (result.detailType === "high") detail = t(state, "clampedHigh");
    else if (result.detailType === "between") {
      detail = replaceTokens(t(state, "interpolation"), [result.lower, result.upper, Math.round(result.ratio * 100)]);
    } else {
      var exactLoad = result.detailType === "exact-upper" ? result.upper : result.lower;
      detail = replaceTokens(t(state, "exactPoint"), [exactLoad]);
    }
    return {
      settings: result.settings,
      loadKg: loadKg,
      detail: detail,
      fixed: false,
      rough: false
    };
  }

  function calculate450(state) {
    var hasLuggage = SCENARIOS[state.scenario].luggage;
    var lowered = state.seat === "lowered";
    var settings = {
      fp: lowered ? { text: "factorySetting" } : { text: "visibleSleeve12" },
      fc: null,
      fr: { value: 10, unit: "click" },
      rp: lowered ? { text: hasLuggage ? "plus6Turns" : "noRearChange" } : { text: hasLuggage ? "plus4Turns" : "springLength204" },
      rc: null,
      rr: { value: 10, unit: "click" }
    };
    var detailKey = lowered ? "mt450DetailLowered" : "mt450DetailStandard";
    return {
      settings: settings,
      loadKg: null,
      detail: replaceTokens(t(state, detailKey), [t(state, hasLuggage ? "withLuggage" : "withoutLuggage")]),
      fixed: true,
      rough: false,
      special: true
    };
  }

  function replaceTokens(text, values) {
    return values.reduce(function (result, value, index) {
      return result.replace(new RegExp("%" + (index + 1), "g"), String(value));
    }, text);
  }

  function renderResults(state) {
    var result = calculate(state);
    state.lastResult = result;
    var model = MODELS[state.model];
    var loadLabel = state.root.querySelector("[data-cfsc-load-label]");
    var loadValue = state.root.querySelector("[data-cfsc-load]");
    if (result.loadKg === null) {
      loadLabel.textContent = t(state, "fixedSetting");
      loadValue.textContent = model.label;
    } else {
      loadLabel.textContent = t(state, "totalLoad");
      loadValue.textContent = formatWeight(state, result.loadKg);
    }

    var html = '<div class="cfsc-model-line"><strong>' + escapeHtml(model.label) + '</strong><span>' + escapeHtml(t(state, state.mode === "rough" ? "rough" : "road")) + '</span></div>' +
      '<p class="cfsc-direction"><strong>' + escapeHtml(t(state, "direction")) + '</strong><span>' + escapeHtml(directionText(state, model)) + '</span></p>' +
      '<div class="cfsc-axles">' +
        axleCard(state, "front", result.settings, model.units) +
        axleCard(state, "rear", result.settings, model.units) +
      '</div>';
    state.root.querySelector("[data-cfsc-results]").innerHTML = html;
    state.root.querySelector("[data-cfsc-detail]").textContent = result.detail;
    state.root.querySelector("[data-cfsc-rough-warning]").hidden = !result.rough;
  }

  function axleCard(state, axle, settings, units) {
    var prefix = axle === "front" ? "f" : "r";
    return '<section class="cfsc-axle"><h4><span aria-hidden="true">' + (axle === "front" ? "F" : "R") + '</span>' + escapeHtml(t(state, axle)) + '</h4><dl>' +
      metricRow(state, "preload", settings[prefix + "p"], units[prefix + "p"]) +
      metricRow(state, "compression", settings[prefix + "c"], units[prefix + "c"]) +
      metricRow(state, "rebound", settings[prefix + "r"], units[prefix + "r"]) +
      '</dl></section>';
  }

  function metricRow(state, labelKey, rawValue, unit) {
    return '<div><dt>' + escapeHtml(t(state, labelKey)) + '</dt><dd>' + escapeHtml(formatSetting(state, rawValue, unit)) + '</dd></div>';
  }

  function formatSetting(state, rawValue, unit) {
    if (rawValue === null || rawValue === undefined || unit === null) return t(state, "notAdjustable");
    if (typeof rawValue === "object") {
      if (rawValue.text) return t(state, rawValue.text);
      return localizedNumber(state, rawValue.value) + " " + t(state, rawValue.unit);
    }
    return localizedNumber(state, rawValue) + " " + t(state, unit);
  }

  function localizedNumber(state, value) {
    return new Intl.NumberFormat(state.language === "ru" ? "ru-RU" : "az-AZ", { maximumFractionDigits: 1 }).format(value);
  }

  function directionText(state, model) {
    var key = {
      "clockwise-stop": "directionClockwise",
      "counterclockwise-stop": "directionCounterclockwise",
      mixed: "directionMixed",
      manual: "directionManual"
    }[model.direction] || "directionManual";
    return t(state, key);
  }

  function formatWeight(state, kilograms) {
    var value = state.unit === "lb" ? kilograms * POUNDS_PER_KILOGRAM : kilograms;
    return localizedNumber(state, Math.round(value * 10) / 10) + " " + state.unit;
  }

  function resultText(state) {
    var result = state.lastResult || calculate(state);
    var model = MODELS[state.model];
    var units = model.units;
    var lines = [
      t(state, "copyHeading"),
      t(state, "model") + ": " + model.label,
      t(state, "mode") + ": " + t(state, state.mode === "rough" ? "rough" : "road"),
      t(state, "direction") + ": " + directionText(state, model)
    ];
    if (!result.rough) lines.push(t(state, "scenario") + ": " + scenarioLabel(state));
    if (result.loadKg !== null) lines.push(t(state, "totalLoad") + ": " + formatWeight(state, result.loadKg));
    if (model.special) lines.push(t(state, "seat") + ": " + t(state, state.seat === "lowered" ? "loweredSeat" : "standardSeat"));
    lines.push("");
    lines.push(t(state, "front") + ":");
    lines.push("- " + t(state, "preload") + ": " + formatSetting(state, result.settings.fp, units.fp));
    lines.push("- " + t(state, "compression") + ": " + formatSetting(state, result.settings.fc, units.fc));
    lines.push("- " + t(state, "rebound") + ": " + formatSetting(state, result.settings.fr, units.fr));
    lines.push("");
    lines.push(t(state, "rear") + ":");
    lines.push("- " + t(state, "preload") + ": " + formatSetting(state, result.settings.rp, units.rp));
    lines.push("- " + t(state, "compression") + ": " + formatSetting(state, result.settings.rc, units.rc));
    lines.push("- " + t(state, "rebound") + ": " + formatSetting(state, result.settings.rr, units.rr));
    lines.push("");
    lines.push(t(state, "details") + ": " + result.detail);
    lines.push(t(state, "safety"));
    return lines.join("\n");
  }

  function scenarioLabel(state) {
    var map = { solo: "solo", luggage: "luggage", passenger: "passenger", "passenger-luggage": "passengerLuggage" };
    if (MODELS[state.model].special && state.scenario === "luggage") return t(state, "threeCases");
    return t(state, map[state.scenario]);
  }

  function copyResult(state) {
    var text = resultText(state);
    var status = state.root.querySelector("[data-cfsc-status]");
    var task;
    if (navigator.clipboard && navigator.clipboard.writeText) {
      task = navigator.clipboard.writeText(text);
    } else {
      task = fallbackCopy(text);
    }
    Promise.resolve(task).then(function () {
      status.textContent = t(state, "copied");
    }).catch(function () {
      status.textContent = t(state, "copyFailed");
    });
  }

  function fallbackCopy(text) {
    return new Promise(function (resolve, reject) {
      var textarea = document.createElement("textarea");
      textarea.value = text;
      textarea.setAttribute("readonly", "");
      textarea.style.position = "fixed";
      textarea.style.opacity = "0";
      document.body.appendChild(textarea);
      textarea.select();
      try {
        if (document.execCommand("copy")) resolve();
        else reject(new Error("copy failed"));
      } catch (error) {
        reject(error);
      } finally {
        textarea.remove();
      }
    });
  }

  function printResult(state) {
    document.body.classList.add("cfsc-print-mode");
    state.root.classList.add("cfsc-print-target");
    var clean = function () {
      document.body.classList.remove("cfsc-print-mode");
      state.root.classList.remove("cfsc-print-target");
      window.removeEventListener("afterprint", clean);
    };
    window.addEventListener("afterprint", clean);
    window.print();
    window.setTimeout(clean, 1500);
  }

  function initAll(scope) {
    var target = scope && scope.querySelectorAll ? scope : document;
    target.querySelectorAll("[data-cfmoto-suspension-calculator]").forEach(function (root, index) {
      init(root, index);
    });
  }

  window.CFMotoSuspensionCalculator = {
    init: init,
    initAll: initAll,
    test: {
      modelIds: Object.keys(MODELS).slice(),
      road: function (modelId, loadKg) {
        var model = MODELS[modelId];
        if (!model || !model.road) return null;
        return interpolate(model, Number(loadKg));
      },
      roundSetting: roundSetting
    }
  };

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", function () { initAll(document); });
  } else {
    initAll(document);
  }
}());
