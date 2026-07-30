# moa — 당신의 순간을 모으다

사진을 온디바이스에서 분석해서 여행, 인물, 반려동물, 장소, 카테고리, 비슷한 사진 앨범으로
자동 정리해주는 iOS 앱입니다. 사진은 기기 밖으로 나가지 않고, 분석도 전부 기기 안에서 처리합니다.

## 주요 기능

- **사진첩** — 라이브러리 전체 사진을 날짜순으로 정렬해서 보여줍니다.
- **자동 분류 앨범** — "분석 시작" 한 번으로 아래 앨범들을 자동으로 만들어줍니다.
  - **여행** — 날짜·위치 정보를 기반으로 여행 구간을 감지해서 묶습니다. 여행 앨범 합치기,
    사진 추가/제거, 동행인(여행자) 연결 기능을 지원합니다.
  - **인물** — Vision 얼굴 인식 + 클러스터링으로 같은 사람이 나온 사진을 묶습니다. 앨범 병합/분리,
    이름 지정이 가능합니다.
  - **반려동물** — 인물과 같은 방식으로 동물 사진을 클러스터링합니다.
  - **장소** — 사진의 위치 좌표를 역지오코딩해서 지역별로 묶습니다(구/군 단위).
  - **분류** — 음식/풍경/도시/이벤트/반려동물/문서/스포츠/차량 등 카테고리로 분류합니다.
  - **중복(비슷한 사진)** — 유사도가 높은 사진들을 묶어서 정리할 수 있게 보여줍니다.
- **사진 뷰어** — 전체화면 뷰어에서 넘기기/선택/삭제가 가능하고, 각 화면(사진첩/앨범 상세/여행
  사진 추가)에서 공통으로 씁니다.
- **마이페이지** — 분석 데이터 용량 확인, 데이터 초기화, 피드백 전송 등을 제공합니다.

## 아키텍처

Tuist 기반 멀티 모듈 + Clean Architecture, 화면 전환은 Coordinator 패턴, 상태는 MVVM(+Combine)으로
관리합니다.

```
Projects/
├── App/           # 앱 진입점 (AppDelegate, SceneDelegate, DI 컨테이너 조립)
├── Domain/        # UseCase, Repository 프로토콜, 순수 모델 — 프레임워크 의존성 없음
├── Data/          # Repository 구현체, SwiftData 엔티티, Vision/Photos/네트워크 서비스
└── Presentation/  # 화면(ViewController/ViewModel/Coordinator), 공통 UI 컴포넌트
```

- **의존 방향**: `App → Presentation → Domain ← Data` (Presentation/Data 모두 Domain에만 의존,
  서로는 모름)
- **저장소**: SwiftData(Core Data 기반) — 사진 메타데이터, 앨범, 얼굴/동물 임베딩, 클러스터 저장
- **분석**: Vision 프레임워크(얼굴 인식, 텍스트 인식, 이미지 분류)로 전부 온디바이스 처리
- **네비게이션**: 각 기능(Album, AlbumDetail, PhotoLibrary, MyPage 등)마다 Coordinator +
  DIContainer가 짝을 이뤄서 화면과 의존성을 조립

## 기술 스택

- Swift, UIKit, Combine, SwiftData
- SnapKit (레이아웃), Moya (네트워킹), Firebase(Core)
- Tuist (프로젝트 생성/모듈 관리)

## 요구 사항

- Xcode 최신 버전, iOS 17.0+
- [Tuist](https://tuist.dev) 4.x (`mise` 또는 `curl -Ls https://install.tuist.io | bash`로 설치)

## 시작하기

```bash
tuist install    # 외부 패키지 의존성 설치 (최초 1회 또는 Package.swift 변경 시)
tuist generate    # Projects.xcworkspace 생성
open Projects.xcworkspace
```

`Project.swift`/`Workspace.swift`를 수정한 뒤에는 항상 `tuist generate`로 다시 생성해야 Xcode에
반영됩니다. `.xcodeproj`/`.xcworkspace`는 커밋하지 않고 매번 생성해서 씁니다.

## 프로젝트 구조 메모

- 번들 ID: `com.baci.moa` (모듈별로는 `com.baci.moa.<module>`)
- 디자인 토큰(색상/타이포/컴포넌트 등)은 `AppStoreAssets/Design/moa_design_spec.html`에 정리되어
  있습니다.
- 마케팅 스크린샷은 `AppStoreAssets/Screenshots/`에 있습니다.
