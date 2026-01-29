<template>
  <div class="calendar-wrapper">
    <div class="calendar-container">
      <!-- 日历头部 -->
      <div class="calendar-header">
        <button class="nav-btn" @click="previousMonth">‹</button>
        <div class="date-selector">
          <select v-model="selectedYear" @change="updateCalendar" class="year-select">
            <option v-for="year in years" :key="year" :value="year">{{ year }}年</option>
          </select>
          <select v-model="selectedMonth" @change="updateCalendar" class="month-select">
            <option v-for="(month, index) in months" :key="index" :value="index + 1">
              {{ month }}
            </option>
          </select>
        </div>
        <button class="nav-btn" @click="nextMonth">›</button>
        <button class="today-btn" @click="goToToday">今天</button>
      </div>

      <!-- 星期标题 -->
      <div class="weekdays">
        <div v-for="day in weekdays" :key="day" class="weekday">{{ day }}</div>
      </div>

      <!-- 日期网格 -->
      <div class="calendar-grid">
        <div v-for="(date, index) in calendarDays" :key="index" class="calendar-day" :class="{
          'other-month': !date.isCurrentMonth,
          'today': date.isToday,
          'weekend': date.isWeekend,
          'holiday': date.isHoliday
        }" @click="selectDate(date)">
          <div class="day-number">{{ date.day }}</div>
          <div v-if="date.lunar" class="lunar-date">{{ date.lunar }}</div>
          <div v-if="date.solarTerm" class="solar-term">{{ date.solarTerm }}</div>
          <div v-if="date.holiday" class="holiday-label">{{ date.holiday }}</div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'

const selectedYear = ref(new Date().getFullYear())
const selectedMonth = ref(new Date().getMonth() + 1)

const weekdays = ['一', '二', '三', '四', '五', '六', '日']
const months = ['1月', '2月', '3月', '4月', '5月', '6月', '7月', '8月', '9月', '10月', '11月', '12月']

// 生成年份列表（当前年份前后各10年）
const years = computed(() => {
  const currentYear = new Date().getFullYear()
  const yearList = []
  for (let i = currentYear - 10; i <= currentYear + 10; i++) {
    yearList.push(i)
  }
  return yearList
})

// 获取农历（简化版，实际应该使用农历库）
const getLunarDate = (year, month, day) => {
  // 这里使用简化的农历转换，实际项目中应该使用专业的农历库
  const lunarMonths = ['正', '二', '三', '四', '五', '六', '七', '八', '九', '十', '冬', '腊']
  const lunarDays = ['初一', '初二', '初三', '初四', '初五', '初六', '初七', '初八', '初九', '初十',
    '十一', '十二', '十三', '十四', '十五', '十六', '十七', '十八', '十九', '二十',
    '廿一', '廿二', '廿三', '廿四', '廿五', '廿六', '廿七', '廿八', '廿九', '三十']

  // 简化处理：返回一个示例农历日期
  const dayIndex = (day - 1) % 30
  const monthIndex = (month - 1) % 12
  return `${lunarMonths[monthIndex]}${lunarDays[dayIndex]}`
}

// 获取节气
const getSolarTerm = (month, day) => {
  const solarTerms = {
    '1-5': '小寒', '1-20': '大寒',
    '2-4': '立春', '2-19': '雨水',
    '3-5': '惊蛰', '3-20': '春分',
    '4-5': '清明', '4-20': '谷雨',
    '5-5': '立夏', '5-21': '小满',
    '6-6': '芒种', '6-21': '夏至',
    '7-7': '小暑', '7-23': '大暑',
    '8-7': '立秋', '8-23': '处暑',
    '9-8': '白露', '9-23': '秋分',
    '10-8': '寒露', '10-23': '霜降',
    '11-7': '立冬', '11-22': '小雪',
    '12-7': '大雪', '12-22': '冬至'
  }
  return solarTerms[`${month}-${day}`] || null
}

// 获取节假日
const getHoliday = (month, day) => {
  const holidays = {
    '1-1': '元旦',
    '2-10': '春节',
    '4-4': '清明',
    '5-1': '劳动节',
    '6-10': '端午',
    '9-15': '中秋',
    '10-1': '国庆'
  }
  return holidays[`${month}-${day}`] || null
}

// 计算日历天数
const calendarDays = computed(() => {
  const year = selectedYear.value
  const month = selectedMonth.value
  const firstDay = new Date(year, month - 1, 1)
  const lastDay = new Date(year, month, 0)
  const daysInMonth = lastDay.getDate()
  const startDay = firstDay.getDay() === 0 ? 6 : firstDay.getDay() - 1 // 转换为周一到周日

  const today = new Date()
  const isToday = (y, m, d) => {
    return y === today.getFullYear() && m === today.getMonth() + 1 && d === today.getDate()
  }

  const days = []

  // 上个月的日期
  const prevMonthLastDay = new Date(year, month - 1, 0).getDate()
  for (let i = startDay - 1; i >= 0; i--) {
    const day = prevMonthLastDay - i
    days.push({
      day,
      year,
      month: month - 1,
      isCurrentMonth: false,
      isToday: false,
      isWeekend: false,
      isHoliday: false,
      lunar: getLunarDate(year, month - 1, day),
      solarTerm: null,
      holiday: null
    })
  }

  // 当前月的日期
  for (let day = 1; day <= daysInMonth; day++) {
    const date = new Date(year, month - 1, day)
    const weekday = date.getDay()
    const isWeekendDay = weekday === 0 || weekday === 6
    const holiday = getHoliday(month, day)

    days.push({
      day,
      year,
      month,
      isCurrentMonth: true,
      isToday: isToday(year, month, day),
      isWeekend: isWeekendDay,
      isHoliday: !!holiday,
      lunar: getLunarDate(year, month, day),
      solarTerm: getSolarTerm(month, day),
      holiday
    })
  }

  // 下个月的日期（填满6行）
  const remainingDays = 42 - days.length
  for (let day = 1; day <= remainingDays; day++) {
    days.push({
      day,
      year,
      month: month + 1,
      isCurrentMonth: false,
      isToday: false,
      isWeekend: false,
      isHoliday: false,
      lunar: getLunarDate(year, month + 1, day),
      solarTerm: null,
      holiday: null
    })
  }

  return days
})

const previousMonth = () => {
  if (selectedMonth.value === 1) {
    selectedMonth.value = 12
    selectedYear.value--
  } else {
    selectedMonth.value--
  }
}

const nextMonth = () => {
  if (selectedMonth.value === 12) {
    selectedMonth.value = 1
    selectedYear.value++
  } else {
    selectedMonth.value++
  }
}

const goToToday = () => {
  const today = new Date()
  selectedYear.value = today.getFullYear()
  selectedMonth.value = today.getMonth() + 1
}

const updateCalendar = () => {
  // 日历会自动更新，因为使用了 computed
}

const selectDate = (date) => {
  console.log('Selected date:', date)
}

onMounted(() => {
  const today = new Date()
  selectedYear.value = today.getFullYear()
  selectedMonth.value = today.getMonth() + 1
})
</script>

<style scoped>
.calendar-wrapper {
  display: flex;
  justify-content: center;
  padding: 2rem 0;
}

.calendar-container {
  background: #ffffff;
  border: 1px solid #e5e7eb;
  border-radius: 16px;
  padding: 1.5rem;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
  max-width: 800px;
  width: 100%;
}

.calendar-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 2rem;
  gap: 1rem;
  flex-wrap: wrap;
}

.date-selector {
  display: flex;
  gap: 0.5rem;
  align-items: center;
}

.year-select,
.month-select {
  background: #ffffff;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  color: #111827;
  padding: 0.5rem 1rem;
  font-size: 0.9rem;
  cursor: pointer;
  transition: all 0.3s ease;
}

.year-select:hover,
.month-select:hover {
  background: #f9fafb;
  border-color: #3b82f6;
}

.nav-btn {
  background: #ffffff;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  color: #111827;
  width: 36px;
  height: 36px;
  font-size: 1.25rem;
  cursor: pointer;
  transition: all 0.3s ease;
  display: flex;
  align-items: center;
  justify-content: center;
}

.nav-btn:hover {
  background: #f9fafb;
  border-color: #3b82f6;
  transform: scale(1.05);
}

.today-btn {
  background: linear-gradient(135deg, #3b82f6 0%, #8b5cf6 100%);
  border: none;
  border-radius: 8px;
  color: #ffffff;
  padding: 0.5rem 1.5rem;
  font-size: 0.9rem;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.3s ease;
}

.today-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(59, 130, 246, 0.4);
}

.weekdays {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 0.5rem;
  margin-bottom: 1rem;
}

.weekday {
  text-align: center;
  font-weight: 600;
  color: #6b7280;
  padding: 0.5rem;
  font-size: 0.85rem;
}

.calendar-grid {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 0.5rem;
}

.calendar-day {
  aspect-ratio: 1;
  background: #f9fafb;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  padding: 0.4rem;
  cursor: pointer;
  transition: all 0.3s ease;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: flex-start;
  position: relative;
  min-height: 70px;
}

.calendar-day:hover {
  background: #f3f4f6;
  border-color: #d1d5db;
  transform: translateY(-2px);
}

.calendar-day.other-month {
  opacity: 0.3;
}

.calendar-day.today {
  background: rgba(59, 130, 246, 0.1);
  border-color: #3b82f6;
  box-shadow: 0 0 0 2px rgba(59, 130, 246, 0.2);
}

.calendar-day.today .day-number {
  color: #3b82f6;
  font-weight: 700;
}

.calendar-day.weekend {
  color: #ef4444;
}

.calendar-day.holiday {
  background: rgba(239, 68, 68, 0.1);
}

.day-number {
  font-size: 0.95rem;
  font-weight: 600;
  color: #111827;
  margin-bottom: 0.15rem;
}

.lunar-date {
  font-size: 0.65rem;
  color: #9ca3af;
  margin-top: 0.15rem;
}

.solar-term {
  font-size: 0.6rem;
  color: #3b82f6;
  font-weight: 500;
  margin-top: 0.15rem;
}

.holiday-label {
  font-size: 0.7rem;
  color: #ff6b6b;
  font-weight: 600;
  margin-top: 0.2rem;
  background: rgba(255, 107, 107, 0.2);
  padding: 0.1rem 0.3rem;
  border-radius: 4px;
}

@media (max-width: 768px) {
  .calendar-container {
    padding: 1rem;
  }

  .calendar-day {
    min-height: 60px;
    padding: 0.3rem;
  }

  .day-number {
    font-size: 0.9rem;
  }

  .lunar-date,
  .solar-term,
  .holiday-label {
    font-size: 0.6rem;
  }
}
</style>
