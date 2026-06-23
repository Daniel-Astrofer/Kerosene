import 'package:flutter/widgets.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Semantic icon catalog for Kerosene.
///
/// Product screens should use this catalog instead of referencing
/// `LucideIcons` or Material `Icons` directly. This keeps visual meaning stable
/// even if the underlying icon pack changes.
class KeroseneIcons {
  const KeroseneIcons._();

  // Navigation
  static const IconData home = LucideIcons.layoutDashboard;
  static const IconData wallet = LucideIcons.walletCards;
  static const IconData history = LucideIcons.scrollText;
  static const IconData settings = LucideIcons.slidersHorizontal;
  static const IconData menu = LucideIcons.menu;

  // Core financial actions
  static const IconData send = LucideIcons.arrowUpRight;
  static const IconData receive = LucideIcons.arrowDownLeft;
  static const IconData download = LucideIcons.download;
  static const IconData internalTransfer = LucideIcons.repeat2;
  static const IconData onchain = LucideIcons.link;
  static const IconData lightning = LucideIcons.zap;
  static const IconData bitcoin = LucideIcons.bitcoin;
  static const IconData fee = LucideIcons.percent;
  static const IconData creditCard = LucideIcons.creditCard;
  static const IconData fiat = LucideIcons.circleDollarSign;
  static const IconData shoppingBag = LucideIcons.shoppingBag;
  static const IconData shoppingCart = LucideIcons.shoppingCart;
  static const IconData quote = LucideIcons.receipt;
  static const IconData settlement = LucideIcons.badgeCheck;

  // Security and identity
  static const IconData security = LucideIcons.shieldCheck;
  static const IconData shield = LucideIcons.shield;
  static const IconData passkey = LucideIcons.keyRound;
  static const IconData biometric = LucideIcons.fingerprint;
  static const IconData totp = LucideIcons.shield;
  static const IconData shares = LucideIcons.layoutGrid;
  static const IconData device = LucideIcons.smartphone;
  static const IconData business = LucideIcons.building2;
  static const IconData lock = LucideIcons.lock;
  static const IconData unlock = LucideIcons.unlock;
  static const IconData user = LucideIcons.user;
  static const IconData userCheck = LucideIcons.userCheck;
  static const IconData userAdd = LucideIcons.userPlus;
  static const IconData userUnavailable = LucideIcons.userX;
  static const IconData accessDenied = LucideIcons.ban;
  static const IconData shieldOff = LucideIcons.shieldOff;
  static const IconData linkUnavailable = LucideIcons.link2Off;
  static const IconData binary = LucideIcons.binary;

  // State and feedback
  static const IconData success = LucideIcons.checkCircle2;
  static const IconData warning = LucideIcons.alertCircle;
  static const IconData error = LucideIcons.alertTriangle;
  static const IconData alert = LucideIcons.alertTriangle;
  static const IconData info = LucideIcons.info;
  static const IconData pending = LucideIcons.clock3;
  static const IconData notifications = LucideIcons.bell;
  static const IconData notificationsOff = LucideIcons.bellOff;
  static const IconData timer = LucideIcons.timer;
  static const IconData timerOff = LucideIcons.timerOff;
  static const IconData serverUnavailable = LucideIcons.serverOff;

  static const IconData review = LucideIcons.shieldAlert;
  static const IconData unavailable = LucideIcons.circleSlash;

  // Utilities
  static const IconData copy = LucideIcons.copy;
  static const IconData paste = LucideIcons.clipboardPaste;
  static const IconData close = LucideIcons.x;
  static const IconData closeCircle = LucideIcons.xCircle;
  static const IconData back = LucideIcons.arrowLeft;
  static const IconData backspace = LucideIcons.delete;
  static const IconData next = LucideIcons.arrowRight;
  static const IconData up = LucideIcons.arrowUp;
  static const IconData down = LucideIcons.arrowDown;
  static const IconData search = LucideIcons.search;
  static const IconData searchUnavailable = LucideIcons.searchX;
  static const IconData check = LucideIcons.check;
  static const IconData circle = LucideIcons.circle;
  static const IconData plus = LucideIcons.plus;
  static const IconData login = LucideIcons.logIn;
  static const IconData eye = LucideIcons.eye;
  static const IconData eyeOff = LucideIcons.eyeOff;

  static const IconData refresh = LucideIcons.refreshCw;
  static const IconData trash = LucideIcons.trash2;
  static const IconData calendar = LucideIcons.calendarClock;
  static const IconData externalLink = LucideIcons.externalLink;
  static const IconData share = LucideIcons.share2;
  static const IconData location = LucideIcons.mapPin;

  static const IconData edit = LucideIcons.edit;
  static const IconData chevronRight = LucideIcons.chevronRight;
  static const IconData chevronLeft = LucideIcons.chevronLeft;
  static const IconData chevronDown = LucideIcons.chevronDown;
  static const IconData moveHorizontal = LucideIcons.moveHorizontal;
  static const IconData trendUp = LucideIcons.trendingUp;

  // Payment interfaces
  static const IconData qr = LucideIcons.qrCode;
  static const IconData nfc = LucideIcons.radio;
  static const IconData scanner = LucideIcons.scanLine;
  static const IconData invoice = LucideIcons.fileText;
  static const IconData document = LucideIcons.scrollText;
  static const IconData fileVerified = LucideIcons.fileCheck2;
  static const IconData inbox = LucideIcons.inbox;
  static const IconData address = LucideIcons.atSign;

  // Network and privacy
  static const IconData network = LucideIcons.network;
  static const IconData tor = LucideIcons.router;
  static const IconData privacy = LucideIcons.eyeOff;
  static const IconData route = LucideIcons.router;
  static const IconData gauge = LucideIcons.gauge;
  static const IconData institution = LucideIcons.landmark;
  static const IconData privateMode = LucideIcons.ghost;
  static const IconData coldWallet = LucideIcons.snowflake;
  static const IconData group = LucideIcons.users;
  static const IconData archive = LucideIcons.box;
  static const IconData database = LucideIcons.database;
  static const IconData server = LucideIcons.server;
  static const IconData stack = LucideIcons.boxes;
  static const IconData globe = LucideIcons.globe2;
  static const IconData sync = LucideIcons.activity;
  static const IconData activity = LucideIcons.activity;
  // Additional semantic aliases used while migrating Material icon callers.
  static const IconData wifiOff = serverUnavailable;
  static const IconData chart = trendUp;
  static const IconData contactless = nfc;
  static const IconData blocked = accessDenied;
  static const IconData undo = refresh;
  static const IconData upload = send;
  static const IconData help = info;
  static const IconData hub = network;
  static const IconData radar = network;
  static const IconData touch = biometric;
  static const IconData schedule = pending;
  static const IconData logout = externalLink;
  static const IconData contrast = circle;
  static const IconData dialpad = shares;
  static const IconData recovery = refresh;
  static const IconData linkOff = linkUnavailable;
  static const IconData cloudOff = serverUnavailable;
  static const IconData devices = device;
  static const IconData historyOff = timerOff;
  static const IconData admin = security;
  static const IconData key = passkey;
  static const IconData keyOff = shieldOff;
  static const IconData personAdd = userAdd;
  static const IconData southWest = receive;
  static const IconData northEast = send;
  static const IconData receipt = invoice;
  static const IconData verified = success;
  static const IconData cancel = closeCircle;
  // Admin/dashboard aliases.
  static const IconData analytics = chart;
  static const IconData badge = userCheck;
  static const IconData dns = network;
  static const IconData language = globe;
  static const IconData layers = stack;
  static const IconData memory = database;
  static const IconData payments = creditCard;
  static const IconData phone = device;
  static const IconData privacyTip = privacy;
  static const IconData swap = moveHorizontal;
  static const IconData visibility = eye;
  static const IconData visibilityOff = eyeOff;
  static const IconData monitor = activity;
}
