# ===========================================================================
# Russian Localization for MT-Notifier
# Andrey Serebryakov, saahov.ru
#
# This program is free software:  You may redistribute it and/or modify it
# it under the terms of the Artistic License version 2 as published by the
# Open Source Initiative.
#
# This program is distributed in the hope that it will be useful but does
# NOT INCLUDE ANY WARRANTY; Without even the implied warranty of FITNESS
# FOR A PARTICULAR PURPOSE.
#
# You should have received a copy of the Artistic License with this program.
# If not, see <http://www.opensource.org/licenses/artistic-license-2.0.php>.
# ===========================================================================
package Notifier::L10N::ru;

use strict;
use base 'Notifier::L10N';
use vars qw( %Lexicon );

%Lexicon = (

      ## plugin

      ## config.yaml (previously Notifier.pl)
      'Subscription options for your Movable Type installation.' => 'Подписки для Movable Type.',
      'Add Subscription(s)' => 'Добавить подписки',
      'Add Subscription Block(s)' => 'Заблокировать подписки',
      'View Subscription Count(s)' => 'Посмотреть счётчик подписок',
      'Write History Records' => 'Записать историю подписок',
      'Block Subscription(s)' => 'Заблокировать подписки',
      'Clear Subscription Block(s)' => 'Снять блокировку подписок',
      'Verify Subscription(s)' => 'Подтвердить подписки',
      'Active Subscriptions' => 'Активные подписки',
      'Blocked Subscriptions' => 'Заблокированные подписки',
      'Pending Subscriptions' => 'Ожидающие подписки',
      'Email' => 'Email',
      'IP Address' => 'IP адрес',

      ## object_types

      ## lib/Notifier/Data.pm
      'Subscription' => 'Подписка',
      'Subscriptions' => 'Подписки',

      ## lib/Notifier/History.pm
      'Subscription History' => 'История подписок',
      'Subscription History Records' => 'Записи истории подписок',

      ## lib/Notifier/Queue.pm
      'Subscription Queue' => 'Очередь отправлений',
      'Subscription Queue Records' => 'Записи очереди отправлений',

      ## modules

      ## lib/Notifier.pm
      'Entry' => 'Запись',
      'Category' => 'Категория',
      'Blog' => 'Блог',
      'subscribe to' => 'подписаться на',
      'opt-out of' => 'отказаться от',
      'Confirmation Subject' => 'Тема уведомления',
      'Confirmation Body' => 'Тело уведомления',
      'Error sending confirmation message to [_1], error [_2]' => 'Ошибка при отправке подтверждающего письма на [_1], ошибка [_2]',
      'Comment' => 'Комментарий',
      'Comment Notification Subject' => 'Тема уведомления о комментарии',
      'Entry Notification Subject' => 'Тема уведомления о записи',
      'Comment Notification Body' => 'Тело сообщения о комментарии',
      'Entry Notification Body' => 'Тело сообщения о записи',

      ## lib/Notifier/Plugin.pm
      'No entry was found to match that subscription record!' => 'Нет записи, соответствующей этой подписке!',
      'No category was found to match that subscription record!' => 'Нет категории, соответствующей этой подписке!',
      'No blog was found to match that subscription record!' => 'Нет блога, соответствующей этой подписке!',
      'The specified email address is not valid!' => 'Указанный адрес электронной почты неправильный!',
      'The requested record key is not valid!' => 'Запрошенный ключ недействителен!',
      'That record already exists!' => 'Подобная запись уже существует!',
      'Your request has been processed successfully!' => 'Ваш запрос был успешно обработан!',
      'Your subscription has been cancelled!' => 'Ваша подписка отменена!',
      'No subscription record was found to match that locator!' => 'Не найдено соответствующих подписок!',
      'Your request did not include a record key!' => 'В вашем запросе отсутствует ключ!',
      'Your request must include an email address!' => 'В вашем запросе отсутствует адрес электронной почты!',
      'Request Processing' => 'Обработка запроса',
      'Unknown' => 'Unknown',
      'Invalid Request' => 'Неверный запрос',
      'Permission denied' => 'Доступ запрещён',
      'Active' => 'Активные',
      'Blocked' => 'Заблокированные',
      'Pending' => 'Ожидающие',
      '[_1] Feed' => '[_1]',
      'Insufficient permissions for installing templates for this weblog.' => 'Недостаточно прав для установки шаблонов в этом блоге.',
      '[_1] Blog Widget' => 'Виджет [_1] для блога',
      '[_1] Category Widget' => 'Виджет [_1] для категорий',
      '[_1] Entry Widget' => 'Виджет [_1] для записей',
      '[_1] Blog Widget: Template Already Exists' => 'Виджет [_1] для блога: шаблон уже существует',
      '[_1] Category Widget: Template Already Exists' => 'Виджет [_1] для категорий: шаблон уже существует',
      '[_1] Entry Widget: Template Already Exists' => 'Виджет [_1] для записей: шаблон уже существует',
      'Error creating new template: [_1]' => 'Ошибка при создании нового шаблона: [_1]',
      'Subscribe to Blog' => 'Подписаться на блог',
      'Subscribe to Category' => 'Подписаться на категорию',
      'Subscribe to Entry' => 'Подписаться на запись',
      'Powered by [_1]' => 'Отправлено [_1]',
      'Go' => 'Выполнить',

      ## lib/Notifier/Util.pm
      'Could not load the [_1] [_2] template!' => 'Не удалось загрузить шаблон [_1] [_2]!',
      'Specified blog unavailable - please check your data!' => 'Указанный блог не найден. Пожалуйста, проверьте параметры.',
      'Invalid sender address - please reconfigure it!' => 'Неправильно настроен адрес отправителя. Пожалуйста, проверьте параметры.',
      'No sender address - please configure one!' => 'Не указан адрес отправителя. Пожалуйста, проверьте параметры.',
      'Invalid URL base value - please check your data ([_1])!' => 'Неправильный базовое значение URL, проверьте параметры ([_1]).',

);

1;
