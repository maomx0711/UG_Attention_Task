/**
 * 实验语音录制工具 — 仅录音模式，支持播放确认
 * 用法: VoiceRecorderKit.attach({ container, key, meta, mode: 'audioOnly' })
 */
window.VoiceRecorderKit = (function() {
    const store = {};
    let mediaRecorder = null;
    let mediaStream = null;
    let activeKey = null;
    let chunks = [];
    let startTime = 0;
    let activeUI = null;
    let activeAudioEl = null;

    function isSupported() {
        return !!(navigator.mediaDevices && navigator.mediaDevices.getUserMedia && window.MediaRecorder);
    }

    function formatDuration(ms) {
        const s = Math.floor(ms / 1000);
        return String(Math.floor(s / 60)).padStart(2, '0') + ':' + String(s % 60).padStart(2, '0');
    }

    function stopActive() {
        if (mediaRecorder && mediaRecorder.state !== 'inactive') {
            try { mediaRecorder.stop(); } catch (e) { /* ignore */ }
        }
        if (mediaStream) {
            mediaStream.getTracks().forEach(t => t.stop());
            mediaStream = null;
        }
        if (activeUI) {
            activeUI.classList.remove('vr-recording');
            const btn = activeUI.querySelector('.vr-btn-record');
            if (btn) {
                btn.textContent = '🎙️ 开始录音';
                btn.classList.remove('vr-recording');
            }
        }
        activeKey = null;
        activeUI = null;
    }

    function attach(options) {
        if (!isSupported()) {
            console.warn('VoiceRecorderKit: 当前浏览器不支持录音');
            return null;
        }

        const mode = options.mode || 'audioOnly';
        const key = options.key;
        const meta = options.meta || {};
        const accent = options.accentColor || '#5c9fd4';
        const container = options.container || (options.textarea && options.textarea.parentNode);

        if (!container) return null;

        if (options.textarea) {
            options.textarea.style.display = 'none';
            const label = options.textarea.closest('p') || options.textarea.previousElementSibling;
            if (label && label.tagName === 'P') label.style.display = 'none';
        }

        stopActive();

        const existing = container.querySelector('.vr-panel[data-key="' + key + '"]');
        if (existing) existing.remove();

        const panel = document.createElement('div');
        panel.className = 'vr-panel';
        panel.dataset.key = key;
        panel.innerHTML = `
            <div class="vr-header">
                <span class="vr-title">🎤 语音作答</span>
                <span class="vr-status" data-status>未录音</span>
            </div>
            <div class="vr-hint">请点击「开始录音」作答，录完后请<strong>播放确认</strong>内容无误，再提交。需允许浏览器使用麦克风。</div>
            <div class="vr-controls">
                <button type="button" class="vr-btn vr-btn-record">🎙️ 开始录音</button>
                <button type="button" class="vr-btn vr-btn-stop" disabled>⏹ 停止录音</button>
                <button type="button" class="vr-btn vr-btn-play" disabled>▶ 播放确认</button>
                <button type="button" class="vr-btn vr-btn-clear" disabled>🗑 重新录制</button>
            </div>
            <div class="vr-wave" style="display:none;"><span></span><span></span><span></span><span></span><span></span></div>
            <div class="vr-player-wrap" style="display:none;">
                <div class="vr-player-label">🔊 录音预览（请播放确认后再提交）</div>
                <audio class="vr-audio" controls preload="auto"></audio>
            </div>
            <div class="vr-confirm-tip" style="display:none;">✅ 录音已保存。请点击播放确认，满意后提交本页。</div>
        `;

        container.appendChild(panel);

        const statusEl = panel.querySelector('[data-status]');
        const btnRecord = panel.querySelector('.vr-btn-record');
        const btnStop = panel.querySelector('.vr-btn-stop');
        const btnPlay = panel.querySelector('.vr-btn-play');
        const btnClear = panel.querySelector('.vr-btn-clear');
        const wave = panel.querySelector('.vr-wave');
        const playerWrap = panel.querySelector('.vr-player-wrap');
        const audioEl = panel.querySelector('.vr-audio');
        const confirmTip = panel.querySelector('.vr-confirm-tip');

        panel.style.setProperty('--vr-accent', accent);

        function setAudioPreview(blob) {
            if (activeAudioEl && activeAudioEl.src) {
                URL.revokeObjectURL(activeAudioEl);
            }
            const url = URL.createObjectURL(blob);
            audioEl.src = url;
            activeAudioEl = audioEl;
            playerWrap.style.display = 'block';
            confirmTip.style.display = 'block';
        }

        function updateStatus() {
            const rec = store[key];
            if (rec && rec.blob) {
                statusEl.textContent = '已录音 ' + formatDuration(rec.durationMs) + ' · 请播放确认';
                statusEl.className = 'vr-status vr-done';
                btnPlay.disabled = false;
                btnClear.disabled = false;
                setAudioPreview(rec.blob);
            } else {
                statusEl.textContent = '未录音';
                statusEl.className = 'vr-status';
                btnPlay.disabled = true;
                btnClear.disabled = true;
                playerWrap.style.display = 'none';
                confirmTip.style.display = 'none';
                audioEl.removeAttribute('src');
            }
        }

        if (store[key] && store[key].blob) updateStatus();

        btnRecord.onclick = async function() {
            if (mediaRecorder && mediaRecorder.state === 'recording') return;
            try {
                mediaStream = await navigator.mediaDevices.getUserMedia({ audio: true });
                const mimeType = MediaRecorder.isTypeSupported('audio/webm;codecs=opus')
                    ? 'audio/webm;codecs=opus' : 'audio/webm';
                chunks = [];
                mediaRecorder = new MediaRecorder(mediaStream, { mimeType });
                startTime = Date.now();
                activeKey = key;
                activeUI = panel;

                mediaRecorder.ondataavailable = e => { if (e.data.size > 0) chunks.push(e.data); };
                mediaRecorder.onstop = function() {
                    const durationMs = Date.now() - startTime;
                    const blob = new Blob(chunks, { type: mimeType });
                    store[key] = {
                        blob, durationMs, mimeType, meta,
                        filename: (meta.filename || key) + '.webm'
                    };
                    if (mediaStream) {
                        mediaStream.getTracks().forEach(t => t.stop());
                        mediaStream = null;
                    }
                    btnRecord.disabled = false;
                    btnStop.disabled = true;
                    panel.classList.remove('vr-recording');
                    wave.style.display = 'none';
                    btnRecord.textContent = '🎙️ 重新录音';
                    updateStatus();
                };

                mediaRecorder.start(200);
                btnRecord.disabled = true;
                btnStop.disabled = false;
                panel.classList.add('vr-recording');
                wave.style.display = 'flex';
                btnRecord.textContent = '🔴 录音中…';
                statusEl.textContent = '录音中…';
                statusEl.className = 'vr-status vr-live';
                playerWrap.style.display = 'none';
                confirmTip.style.display = 'none';
            } catch (err) {
                alert('无法访问麦克风：' + (err.message || '请检查浏览器权限设置'));
            }
        };

        btnStop.onclick = function() {
            if (mediaRecorder && mediaRecorder.state === 'recording') mediaRecorder.stop();
        };

        btnPlay.onclick = function() {
            const rec = store[key];
            if (!rec || !rec.blob) return;
            if (!audioEl.src) setAudioPreview(rec.blob);
            audioEl.play();
        };

        btnClear.onclick = function() {
            if (confirm('确定删除本条录音并重新录制吗？')) {
                delete store[key];
                btnRecord.textContent = '🎙️ 开始录音';
                if (audioEl.src) {
                    URL.revokeObjectURL(audioEl.src);
                    audioEl.removeAttribute('src');
                }
                updateStatus();
            }
        };

        return { key, hasRecording: () => hasRecording(key), getRecording: () => store[key] || null };
    }

    function getByKey(key) { return store[key] || null; }
    function getAll() { return Object.entries(store).map(([k, v]) => ({ key: k, ...v })); }

    function hasRecording(key) {
        const rec = store[key];
        return !!(rec && rec.blob);
    }

    function bindSubmitValidation(formOrBtn, key, message) {
        const msg = message || '请先录制语音，并播放确认后再提交。';
        const btn = typeof formOrBtn === 'string' ? document.getElementById(formOrBtn) : formOrBtn;
        if (!btn) return;
        btn.addEventListener('click', function(e) {
            if (!hasRecording(key)) {
                e.preventDefault();
                e.stopImmediatePropagation();
                alert(msg);
                return false;
            }
        }, true);
    }

    function downloadAll(prefix) {
        const all = getAll();
        if (!all.length) { alert('没有可下载的录音文件。'); return; }
        all.forEach(rec => {
            const a = document.createElement('a');
            a.href = URL.createObjectURL(rec.blob);
            a.download = prefix + '_' + (rec.filename || rec.key + '.webm');
            a.click();
            setTimeout(() => URL.revokeObjectURL(a.href), 1000);
        });
    }

    function getManifest() {
        return getAll().map(rec => ({
            key: rec.key,
            filename: rec.filename,
            durationMs: rec.durationMs,
            mimeType: rec.mimeType,
            meta: rec.meta
        }));
    }

    return {
        isSupported, attach, stopActive,
        getByKey, getAll, hasRecording, bindSubmitValidation,
        downloadAll, getManifest
    };
})();
