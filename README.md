
# 🛍 MEMORY MARKET  
Flutter 기반 상품 등록 · 수정 · 삭제 · 장바구니 앱  

---

## 📌 프로젝트 개요
**MEMORY MARKET**은 Flutter를 이용한 상품 관리 & 장바구니 기능 데모 앱입니다.  
사용자는 상품을 등록하고, 이미지를 첨부하며, 수정·삭제·장바구니 담기까지  
쇼핑몰의 핵심 흐름을 하나의 앱 안에서 경험할 수 있습니다.

---

## 🧩 주요 기능

| 구분 | 기능 설명 |
|------|------------|
| 상품 등록 | 상품 이름, 가격, 설명, 이미지 등록 가능 (`image_picker`) |
| 상품 수정/삭제 | 상세 페이지에서 상품 정보 수정 또는 삭제 |
| 목록 표시 | 상품 목록을 `ListView.builder`로 동적 표시 |
| 상세 보기 | 상품 이미지, 설명, 가격 표시 + 장바구니 담기 |
| 장바구니 | 수량 조절, 개별 삭제, 총액 계산, 구매하기 버튼 |
| 가격 포맷 | `intl` 패키지를 통한 `1,000원` 단위 포맷 |

---

## 🧱 프로젝트 구조

lib/
├─ main.dart # 전체 앱 진입점
├─ models/
│ ├─ product.dart # 상품 데이터 모델
│ └─ cart_item.dart # 장바구니 아이템 모델
├─ pages/
│ ├─ item_list_page.dart # 상품 목록 페이지
│ ├─ product_detail.dart # 상품 상세 페이지 (수정/삭제/장바구니)
│ ├─ edit_product.dart # 상품 등록 및 수정 페이지
│ └─ cart_page.dart # 장바구니 페이지
├─ widgets/
│ └─ rounded_thumb.dart # 둥근 썸네일 이미지 위젯


(※ 현재 버전에서는 모든 코드가 `main.dart`에 통합되어 있습니다.)

---

## 📦 의존성
`pubspec.yaml` 파일에 다음 의존성을 추가하세요.

```yaml
dependencies:
  flutter:
    sdk: flutter
  intl: ^0.20.0
  image_picker: ^1.1.2
