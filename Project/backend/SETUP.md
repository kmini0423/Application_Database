# Backend 설정 가이드 (한글)

터미널을 **프로젝트 루트**(`Project` 폴더)에서 연 다음, 아래 순서대로 진행하세요.

---

## 1단계: backend 폴더로 이동

```bash
cd "/Users/kyungminkim/Desktop/Kyungmin/2026 Spring/CS 348/Project/backend"
```

이후 모든 명령어는 이 `backend` 폴더에서 실행합니다. (`cd backend`만 쓰면 이미 backend 안에 있을 때는 "no such file or directory"가 납니다.)

---

## 2단계: Python 패키지 설치 (Flask 등)

```bash
pip3 install -r requirements.txt
```

또는:

```bash
python3 -m pip install -r requirements.txt
```

`ModuleNotFoundError: No module named 'flask'` 는 이 단계를 하지 않아서 발생합니다.

---

## 3단계: MySQL 비밀번호 확인

Homebrew MySQL은 처음에 **root 비밀번호가 비어 있는 경우**가 많습니다.

**비밀번호 없이 접속 시도:**

```bash
mysql -u root < database/schema.sql
```

- **에러 없이 끝나면:** root 비밀번호가 없는 것이므로, 4단계에서 `.env`에 `DB_PASSWORD=` (빈 값)으로 두면 됩니다.
- **`ERROR 1045 (28000): Access denied` 가 나오면:** root에 비밀번호가 있는 것이므로, 그 비밀번호를 기억해 두었다가 4단계 `.env`의 `DB_PASSWORD`에 넣고, 5단계에서는 `mysql -u root -p` 후 비밀번호를 입력해 스키마를 실행하면 됩니다.

---

## 4단계: .env 파일 만들기

```bash
cp env.example .env
```

`.env` 파일을 열어서 수정합니다.

- **MySQL root 비밀번호가 없는 경우:**
  ```env
  DB_PASSWORD=
  ```
- **MySQL root 비밀번호가 있는 경우:**
  ```env
  DB_PASSWORD=여기에_비밀번호
  ```

나머지 값은 그대로 두어도 됩니다.

---

## 5단계: DB·테이블 생성 (스키마 실행)

**비밀번호가 없을 때:**

```bash
mysql -u root < database/schema.sql
```

**비밀번호가 있을 때:**

```bash
mysql -u root -p < database/schema.sql
```

프롬프트가 나오면 MySQL root 비밀번호를 입력합니다.

---

## 6단계: Flask 서버 실행

```bash
python3 app.py
```

`Running on http://0.0.0.0:5001` 이 보이면 성공입니다. 이제 앱에서 회원가입/로그인을 시도해 보세요.

---

## 자주 나오는 에러 정리

| 에러 | 원인 | 해결 |
|------|------|------|
| `No module named 'flask'` | Flask 미설치 | 2단계 `pip3 install -r requirements.txt` 실행 |
| `Access denied (using password: YES)` | 잘못된 MySQL 비밀번호 | 3단계로 비밀번호 유무 확인 후 `.env`의 `DB_PASSWORD` 수정 |
| `Access denied` (비밀번호 없이 실행 시) | root에 비밀번호가 설정됨 | `.env`에 올바른 `DB_PASSWORD` 입력하고 `mysql -u root -p` 사용 |
| `cd backend` → no such file or directory | 이미 backend 안에 있음 | 1단계처럼 전체 경로로 `cd .../Project/backend` 한 번만 실행 |

---

## MySQL root 비밀번호를 잊었을 때 (Homebrew)

```bash
# MySQL 중지
brew services stop mysql

# 안전 모드로 MySQL 실행 (비밀번호 없이)
mysqld_safe --skip-grant-tables &

# 새 터미널에서
mysql -u root

# MySQL 콘솔 안에서 비밀번호 재설정 (MySQL 8.0)
ALTER USER 'root'@'localhost' IDENTIFIED BY '새비밀번호';
FLUSH PRIVILEGES;
EXIT;

# mysqld_safe 종료 후 MySQL 재시작
brew services start mysql
```

이후 `.env`의 `DB_PASSWORD`를 `새비밀번호`로 맞추면 됩니다.
