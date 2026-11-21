/**
 * 위시 문서가 바뀔 때 더는 쓰지 않는 사진 파일 이름을 고른다 (GH-93 R-42, 설계 §7).
 * - 삭제 표시가 새로 붙으면 그 위시의 사진을 지운다. 삭제가 이기므로 updatedAt과 상관없다.
 * - 사진 이름이 바뀌면(바꾸기·지우기) 예전 사진을 지운다. 단, 늦게 올라온 옛 값(updatedAt이 더 작음)이면 지우지 않는다.
 *   더 새 값을 가진 기기가 곧 다시 올려 되돌리는데, 그때 그 사진 파일이 서버에 남아 있어야 한다.
 * 사진 이름은 `{위시id}-{uuid}.jpg`라 다른 위시와 겹치지 않는다.
 */
export function photoToDelete(before, after) {
  const name = before?.photoFileName;
  if (!name) return null;
  const wasDeleted = before.deletedAt != null;
  const isDeleted = after?.deletedAt != null;
  if (isDeleted && !wasDeleted) return name;
  if (after?.photoFileName === name) return null;
  if ((after?.updatedAt ?? 0) < (before.updatedAt ?? 0)) return null;
  return name;
}

/** 고른 사진을 Storage에서 지운다. 이미 없으면 그대로 둔다(재시도 안전). 지운 파일 경로를 돌려준다 */
export async function cleanupWishPhoto({ bucket, before, after }) {
  const name = photoToDelete(before, after);
  const ownerUid = before?.ownerUid;
  if (!name || !ownerUid) return null;
  const path = `wishPhotos/${ownerUid}/${name}`;
  await bucket.file(path).delete({ ignoreNotFound: true });
  return path;
}
