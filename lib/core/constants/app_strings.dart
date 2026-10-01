/// Все тексты приложения.
///
/// Когда добавим локализацию, заменяется только этот файл на
/// `AppLocalizations` — остальной код не трогается.
class AppStrings {
  const AppStrings._();

  static const String appName = 'WarderDo';

  // --- Приветствие ---
  static const String welcomeTitle = 'Найдите время\nдля важного';
  static const String welcomeSubtitle =
      'Создавайте маленькие привычки, которые дают больше энергии, фокуса '
      'и времени для себя.';
  static const String getStarted = 'Начать';
  static const String haveAccount = 'Уже есть аккаунт? ';
  static const String signIn = 'Войти';
  static const String signInWithTelegram = 'Войти через Telegram';
  static const String telegramLoginTitle = 'Подтвердите вход в Telegram';
  static const String telegramLoginBody =
      'Нажмите «Войти» в боте. Код в боте должен совпадать с этим:';
  static const String openTelegram = 'Открыть Telegram';
  static const String telegramLoginWaiting = 'Ждём подтверждения…';
  static const String telegramLoginCancelled = 'Вход отменён';
  static const String telegramLoginExpired =
      'Время на вход истекло. Попробуйте ещё раз';
  static const String telegramNotInstalled =
      'Не удалось открыть Telegram. Установите его и попробуйте снова';
  static const String orEmail = 'или с email';

  // --- Вход ---
  static const String loginTitle = 'С возвращением';
  static const String loginSubtitle =
      'Войдите, чтобы продолжить свои привычки.';
  static const String email = 'Email';
  static const String emailHint = 'вы@example.com';
  static const String password = 'Пароль';
  static const String passwordHint = 'Минимум 8 символов';
  static const String loginAction = 'Войти';
  static const String noAccount = 'Нет аккаунта? ';
  static const String signUp = 'Зарегистрироваться';
  static const String showPassword = 'Показать пароль';
  static const String hidePassword = 'Скрыть пароль';

  // --- Регистрация ---
  static const String registerTitle = 'Создайте аккаунт';
  static const String registerSubtitle =
      'Сделайте первый маленький шаг сегодня.';
  static const String fullName = 'Имя';
  static const String fullNameHint = 'Необязательно';
  static const String confirmPassword = 'Подтвердите пароль';
  static const String registerAction = 'Продолжить';
  static const String timezone = 'Часовой пояс';

  // --- Профиль ---
  static const String profileTitle = 'Настройки';
  static const String account = 'Аккаунт';
  static const String session = 'Сессия';
  static const String registeredAt = 'Зарегистрирован: ';
  static const String save = 'Сохранить';
  static const String logout = 'Выйти';
  static const String logoutConfirmTitle = 'Выйти из аккаунта?';
  static const String logoutConfirmBody =
      'В следующий раз для входа понадобятся email и пароль.';
  static const String cancel = 'Отмена';
  static const String profileSaved = 'Профиль обновлён';
  static const String signInMethod = 'Вход';
  static const String organize = 'Организация';
  static const String groupsMenu = 'Группы';
  static const String reorderMenu = 'Изменить порядок';
  static const String notifications = 'Уведомления';
  static const String taskLeadTitle = 'Напомнить заранее';
  static const String taskLeadAuto = 'Авто';
  static const String botRemindersHint =
      'Напоминания приходят в Telegram-бот. О задачах бот предупреждает '
      'заранее («Авто» — за 10 минут).';
  static const String botChat = 'Чат с ботом';
  static const String botUrl = 'https://t.me/warder_do_bot';
  static const String viaTelegram = 'Через Telegram';

  // --- Валидация ---
  static const String errEmailRequired = 'Введите email';
  static const String errEmailInvalid = 'Неверный формат email';
  static const String errPasswordRequired = 'Введите пароль';
  static const String errPasswordShort = 'Пароль не короче 8 символов';
  static const String errPasswordLong = 'Пароль не длиннее 128 символов';
  static const String errPasswordBytes =
      'Пароль слишком длинный (не более 72 байт)';
  static const String errPasswordMismatch = 'Пароли не совпадают';
  static const String errNameLong = 'Имя не длиннее 255 символов';

  // --- Сеть и сервер ---
  static const String errNoInternet = 'Нет подключения к интернету';
  static const String errTimeout = 'Сервер не ответил. Попробуйте ещё раз';
  static const String errServer = 'Ошибка сервера. Попробуйте позже';
  static const String errUnknown = 'Произошла неизвестная ошибка';
  static const String errInvalidCredentials = 'Неверный email или пароль';
  static const String errAccountBlocked = 'Ваш аккаунт заблокирован';
  static const String errEmailTaken = 'Этот email уже зарегистрирован';
  static const String errSessionExpired = 'Сессия истекла. Войдите снова';
  static const String errValidation = 'Проверьте введённые данные';
  static const String errNotFound = 'Не найдено';
  static const String errConflict = 'Действие конфликтует с текущими данными';
  static const String errNotAHabit =
      'Не похоже на привычку или задачу. Например: «завтра в 15:00 к врачу»';
  static const String errPrivateBot = 'Это личный бот — доступ закрыт';
  static const String errTelegramAuth =
      'Не удалось войти через Telegram. Откройте приложение из бота заново';
  static const String errProgramExists =
      'У этой привычки уже есть активная программа';

  // --- Нижняя навигация ---
  static const String tabHabits = 'Привычки';
  static const String tabStats = 'Статистика';
  static const String tabSettings = 'Настройки';

  // --- Сегодня (главный экран) ---
  static const String today = 'Сегодня';
  static const String tomorrow = 'Завтра';
  static const String yesterday = 'Вчера';
  static const String progressToday = 'Прогресс дня';

  // --- Меню «+» ---
  static const String addMenuTitle = 'Добавить';
  static const String addMenuAi = 'Описать словами';
  static const String addMenuAiHint = 'AI поймёт дату, время и цель';
  static const String addMenuTemplates = 'Из шаблонов';
  static const String addMenuTemplatesHint = 'Готовые привычки на каждый день';
  static const String addMenuCustom = 'Своя привычка';
  static const String addMenuCustomHint = 'Заполнить всё самому';
  static const String addMenuProgram = 'Программа тренировок';
  static const String addMenuProgramHint = 'AI составит план на N дней';

  // --- Задачи на «Сегодня» ---
  static const String tasksSection = 'Задачи';
  static const String overdue = 'просрочено';
  static const String noTime = 'Без времени';
  static const String markedDone = 'Отмечено';
  static const String undo = 'Отменить';
  static const String progressAllDone = 'Всё выполнено! 🎉';
  static const String todayEmptyTitle = 'На этот день привычек нет';
  static const String todayEmptyBody =
      'Добавьте привычку или выберите другой день.';
  static const String addHabit = 'Добавить привычку';
  static const String retry = 'Повторить';
  static const String clearLog = 'Убрать отметку';
  static const String addProgress = 'Добавить';
  static const String customAmount = 'Другое количество';
  static const String everyDay = 'Каждый день';
  static const String noSchedule = 'Без расписания';
  static const String byProgram = 'По программе';
  static const String once = 'Один раз';

  // --- Напоминание заранее ---
  static const String remindBeforeLabel = 'Напомнить заранее';
  static const String remindBeforeAuto = 'Авто';
  static const String remindBeforeAutoHint =
      'Задачи — за 10 мин, привычки — нет';
  static const String remindBeforeOff = 'Не напоминать';
  static const String remindBeforeFormat = 'За %s мин';
  static const String remindBeforeHour = 'За 1 час';
  static const String pickDate = 'Выберите дату';
  static const String otherDate = 'Другая дата';

  // --- AI: быстрое добавление ---
  static const String quickAddEntry = 'Описать словами (AI)';
  static const String quickAddTitle = 'Добавить с AI';
  static const String quickAddSubtitle =
      'Напишите привычку или задачу своими словами — дату, время и цель '
      'AI найдёт сам. Перед сохранением всё можно поправить.';
  static const String quickAddHint = 'Например: завтра в 15:00 к врачу';
  static const String quickAddAction = 'Создать';
  static const String byProgramHint =
      'Расписание задаёт программа тренировок — его нельзя изменить вручную.';

  /// «Раз в N дней» — число подставляется на месте `%s`.
  static const String everyNDays = 'Раз в %s дней';

  // --- Достижения ---
  static const String newAchievement = 'Новое достижение!';
  static const String achievementCongrats =
      'Поздравляем! Продолжайте в том же духе!';
  static const String great = 'Отлично';

  // --- Статистика ---
  static const String statsSoonTitle = 'Статистика скоро появится';
  static const String statsSoonBody =
      'Здесь будут серии, проценты выполнения и достижения.';
  static const String statsTitle = 'Статистика';
  static const String statsSelectedHabits = 'Выбранные привычки';
  static const String statsAllHabits = 'Все привычки';
  static const String statsRecords = 'Записи';
  static const String statsCurrentStreak = 'Текущая серия';
  static const String statsBestStreak = 'Лучшая серия';
  static const String statsCompleted = 'Выполнено';
  static const String statsSuccessRate = 'Успешность';
  static const String statsLast7 = 'Последние 7 дней';
  static const String statsLast30 = 'Последние 30 дней';
  static const String statsLast90 = 'Последние 90 дней';
  static const String statsEmpty = 'Пока нет данных';
  static const String statsEmptyBody =
      'Отмечайте привычки — и здесь появится ваша статистика.';

  /// Именительный падеж — для заголовка календаря («Сентябрь 2025»).
  static const List<String> monthsNominative = [
    'Январь',
    'Февраль',
    'Март',
    'Апрель',
    'Май',
    'Июнь',
    'Июль',
    'Август',
    'Сентябрь',
    'Октябрь',
    'Ноябрь',
    'Декабрь',
  ];

  /// Сокращения месяцев — для диапазона недели («15–21 сент.»).
  static const List<String> monthsShort = [
    'янв.',
    'фев.',
    'мар.',
    'апр.',
    'мая',
    'июн.',
    'июл.',
    'авг.',
    'сент.',
    'окт.',
    'нояб.',
    'дек.',
  ];

  // --- Группы ---
  static const String groups = 'Группы';
  static const String templates = 'Шаблоны';
  static const String searchTemplates = 'Поиск шаблонов';
  static const String customSection = 'Пользовательские';
  static const String createOwnGroup = 'Создать свою группу';
  static const String addGroup = 'Добавить группу';
  static const String editGroup = 'Изменить группу';
  static const String appearance = 'Оформление';
  static const String general = 'Основные';
  static const String nameLabel = 'Название';
  static const String colorLabel = 'Цвет';
  static const String iconLabel = 'Иконка';
  static const String notificationsLabel = 'Уведомления';
  static const String notificationsHint =
      'Уведомления настраиваются у самой привычки';
  static const String none = 'Нет';
  static const String errNameRequired = 'Введите название';
  static const String deleteGroupTitle = 'Удалить группу?';
  static const String deleteGroupBody =
      'Группа будет удалена, но привычки внутри сохранятся — они останутся '
      'без группы.';
  static const String delete = 'Удалить';
  static const String nothingFound = 'Ничего не найдено';

  // --- Календарь ---
  static const List<String> weekdayShort = [
    'Пн',
    'Вт',
    'Ср',
    'Чт',
    'Пт',
    'Сб',
    'Вс',
  ];

  static const List<String> weekdayFull = [
    'Понедельник',
    'Вторник',
    'Среда',
    'Четверг',
    'Пятница',
    'Суббота',
    'Воскресенье',
  ];

  static const List<String> months = [
    'января',
    'февраля',
    'марта',
    'апреля',
    'мая',
    'июня',
    'июля',
    'августа',
    'сентября',
    'октября',
    'ноября',
    'декабря',
  ];

  // --- Создание привычки ---
  static const String newHabit = 'Новая привычка';
  static const String editHabit = 'Изменить привычку';
  static const String chooseHabit = 'Выберите привычку';
  static const String templatesTitle = 'Шаблоны';
  static const String allCategories = 'Все';
  static const String customHabit = 'Своя привычка';
  static const String customHabitHint = 'Создать с нуля';
  static const String searchHabits = 'Поиск привычек';
  static const String titleHint = 'Название привычки';
  static const String continueAction = 'Продолжить';
  static const String errTitleRequired = 'Введите название';
  static const String habitCreated = 'Привычка создана';
  static const String habitUpdated = 'Изменения сохранены';
  static const String editAction = 'Изменить';

  static const String catGood = 'Хорошие';
  static const String catHealth = 'Здоровье';
  static const String catBad = 'Плохие';
  static const String catTask = 'Задачи';

  static const String typeLabel = 'Тип';
  static const String typeGood = 'Хорошая привычка';
  static const String typeBad = 'Плохая привычка';
  static const String typeTask = 'Привычка-задача';

  static const String groupLabel = 'Группы';
  static const String noGroup = 'Без группы';

  static const String goalLabel = 'Цель';
  static const String goalNone = 'Нет';
  static const String goalValueLabel = 'Значение';
  static const String goalUnitLabel = 'Единица';
  static const String goalTypeLabel = 'Тип цели';
  static const String goalAtLeast = 'Не менее';
  static const String goalAtMost = 'Не более';
  static const String goalExact = 'Ровно';
  static const String goalRemove = 'Без цели';

  static const String repeatLabel = 'Повтор';
  static const String repeatDaily = 'Каждый день';
  static const String repeatWeekly = 'Дни недели';
  static const String repeatInterval = 'С интервалом';
  static const String repeatOnce = 'Один раз';
  static const String repeatIntervalHint = 'Раз в сколько дней';
  static const String errWeekdaysRequired = 'Выберите хотя бы один день';

  static const String remindersLabel = 'Уведомления';
  static const String remindersEmpty = 'Нет';
  static const String addReminder = 'Добавить напоминание';
  static const String remindersHint =
      'Напоминания приходят с телефона, сервер их не отправляет.';

  static const String descriptionLabel = 'Описание';
  static const String descriptionEmpty = 'Пусто';
  static const String descriptionHint = 'Зачем вам эта привычка?';

  static const String done = 'Готово';

  // --- Изменить порядок ---
  static const String reorderTitle = 'Изменить порядок';
  static const String reorderEmpty = 'Пока нет ни привычек, ни групп';
  static const String reorderHint =
      'Тяните за ручку справа. Привычку можно перенести в другую группу.';
  static const String deleteHabitTitle = 'Удалить привычку?';
  static const String deleteHabitBody =
      'Привычка и вся её история удалятся навсегда. Отменить это нельзя — '
      'если нужно просто убрать её из списка, лучше архивировать.';
  static const String archive = 'Архивировать';
  static const String saved = 'Сохранено';
  static const String edit = 'Править';
  static const String doneEditing = 'Готово';
  static const String groupsEmpty = 'Групп пока нет';
  static const String groupsEmptyBody =
      'Группы помогают разложить привычки по времени дня или сферам жизни.';
  static const String groupsHint =
      'Нажмите на группу, чтобы перетащить в неё привычки.';
}
