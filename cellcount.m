
clear

im_dir = '';
dd_save = '';

img = imread(im_dir);
sz = size(img);

bw = img(:,:,1)<170;
bw = imfill(bw, 'hole');
%figure, imshow(bw)

cc = bwlabel(bw, 4);
stats = regionprops(cc, 'Area','Perimeter','Image','BoundingBox','Centroid', 'MinorAxisLength', 'MajorAxisLength');

cc_majAx = [stats.MajorAxisLength]; 
%figure, histogram(cc_majAx, 200)

majAxThresholds = [30 110];

correct_obj =  find(cc_majAx >= majAxThresholds(1) & cc_majAx <= majAxThresholds(2));

cents = {stats(correct_obj).Centroid}; cents = floor(cell2mat(cents')); 
l_cents = sub2ind([sz(1), sz(2)], cents(:,2), cents(:,1));
rep = false(sz(1), sz(2)); rep(l_cents) = true;
%figure, imshow(img(:,:,1)); hold on; [Cr_b, Cc_b] = find(rep); scatter(Cc_b,Cr_b,15,'r','filled'); hold off

mask = true(sz(1), sz(2));
large_obj =  find(cc_majAx > majAxThresholds(2));
himg = rgb2hsv(img); himg = himg(:,:,2);
x = 3; intensity_thr = 0.3; graydist_thr = 3;
for i = 1:length(large_obj)
    bb = stats(large_obj(i)).BoundingBox;
    maskwin = mask(floor((bb(2))+1):(floor(bb(2))+ bb(4)), (floor(bb(1))+1):(floor(bb(1))+bb(3)));

    D = himg(floor((bb(2))+1):(floor(bb(2))+bb(4)), (floor(bb(1))+1):(floor(bb(1))+bb(3)));
    m = false(size(D)); m(x:end-(x-1), x:end-(x-1)) = true;
    Dfil = imgaussfilt(D, 1).*m;

    regmax = imregionalmax(Dfil).*(stats(large_obj(i)).Image > 0);
    regmaxidx = find(regmax(:));
    if sum(regmax(:)) > 1
        regmaxval = Dfil(regmaxidx);
        bigmaxidx = find(regmaxval > intensity_thr);

        regmaxidx = regmaxidx(bigmaxidx);
        regmaxval = Dfil(regmaxidx);
        [regmaxval,iii] = sort(regmaxval,1,'descend');
        regmaxidx = regmaxidx(iii);
        flags = true(size(regmaxval));
        gDfil = imgradient(Dfil).*m;
        for j = 1:length(regmaxval)
            if flags(j) 
                t = graydist(gDfil, regmaxidx(j));
                for k = (j+1):length(regmaxval)
                    if t(regmaxidx(k))<graydist_thr
                        flags(k) = 0;
                    end
                end
            end
        end
        regmaxidx = regmaxidx(flags);
    end

    [rr, cc] = ind2sub(size(D), regmaxidx);
    inx = sub2ind([sz(1), sz(2)], rr+floor(bb(2)), cc+floor(bb(1)));
    rep(inx) = true;

end
figure, imshow(img(:,:,1:3)); hold on; [Cr_b, Cc_b] = find(rep); scatter(Cc_b,Cr_b,15,'r','filled'); hold off

[~, fnname, ~] = fileparts(fn1);
fnsave = [dd_save, '\', fnname, '.png'];
export_fig(fnsave)
close

cell_count = length(find(rep));
fnsave = [dd_save, '\', fnname, '.mat'];
save(fnsave, 'rep', 'cell_count', '-v7.3')




