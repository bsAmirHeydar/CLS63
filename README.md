# CLS63
this is my project to CLS63!
I bought my CLS63 with this project!
:)

this is 20 Sep! and I'm back again after I destroyed in  merceyless storm
:)

again I'm back. back to my prime. 22 Dec 2025.
:)

in another time I'm going back again. 23 Feb 2026
:)

## NDS Final Trading Logic (طبق جزوه)

### 1) Market Reading
- نودها: قله/دره با `pivot_depth`.
- سکانس: نگاه از آخر به اول، شماره‌گذاری از اول به آخر.
- هوک مثبت: شروع از دره‌ای که هنوز شکسته نشده (`start_unbroken`).
- هوک منفی: شروع از قله‌ای که هنوز شکسته نشده (`start_unbroken`).
- تایم‌فریم اسکن هوک فقط: `M1, M5, M15, H1, H4, D1`.
- اگر طول سکانس از 4 بیشتر شود، اسکن به تایم‌فریم بالاتر سوییچ می‌شود.

### 2) Core Setup
- وجود دو هوک هم‌جهت (`Hook1` و `Hook2`) لازم است.
- ملاک ورود، دیدن Rally_1 نیست.
- ورود روی `Near Death` هوک دوم انجام می‌شود.

### 3) Entry (کاملا Reverse)
- ورود فقط `Limit` و خلاف جهت حرکت تند فعلی قیمت.
- ناحیه ورود: حوالی `86.4%` هوک دوم (ND level).
- Buy: وقتی قیمت با فشار می‌ریزد داخل ND هوک 2 مثبت.
- Sell: وقتی قیمت با فشار صعود می‌کند داخل ND هوک 2 منفی.
- تایید نهایی روی LTF با ساختار فلگ/123 انجام می‌شود.

### 4) Stop Loss
- استاپ دقیقا پشت همان Hook2 مبنای ورود:
- Buy: زیر اکسترم/`Z2` هوک دوم.
- Sell: بالای اکسترم/`Z2` هوک دوم.

### 5) Exit Management
- Trailing Stop نداریم.
- خروج با TP و کاهش حجم (partial) انجام می‌شود.
- خروج کامل در ابطال ساختار Hook2.

### 6) Risk
- ریسک دلاری ثابت است.
- حجم باید طوری محاسبه شود که برخورد به SL دقیقا همان مبلغ ریسک دلاری را کم کند.

### 7) Out of Scope (در این منطق نیست)
- ورود بر پایه Market/Stop.
- وابسته کردن ورود به اینکه Rally_1 حتما دیده شود.
- تریلینگ استاپ.
