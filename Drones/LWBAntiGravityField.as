void onInit(CBlob@ this)
{
	this.server_SetTimeToDie(10);
	this.getShape().SetRotationsAllowed(false);
}

void onTick(CBlob@ this)
{
	Vec2f pos = this.getPosition();

	CBlob@[] blobs;
	this.getMap().getBlobsInRadius(pos, 50.0f, @blobs);
	for (int i = 0; i < blobs.size(); i++)
	{
		if (blobs[i].getTeamNum() != this.getTeamNum() && !blobs[i].hasTag("prevent_antigravity")) blobs[i].AddForce(Vec2f(0.0f, blobs[i].getMass() * -0.5f));
	}

	if (!getNet().isClient()) return;

	SColor color;
	switch (this.getTeamNum())
	{
		case 0:
		color = SColor(0xf01d85ab);
		break;

		case 1:
		color = SColor(0xf0b73333);
		break;
		
		case 2:
		color = SColor(0xf0649b0d);
		break;
		
		case 3:
		color = SColor(0xf09e3abb);
		break;
		
		case 4:
		color = SColor(0xf0cd6120);
		break;
		
		case 5:
		color = SColor(0xf04f9b7f);
		break;
		
		case 6:
		color = SColor(0xf04149f0);
		break;
		
		default:
		color = SColor(0xf097a792);
		break;
	}


	for (int i = 0; i < 4; i++)
	{
		CParticle@ p1 = ParticlePixelUnlimited(pos + Vec2f(50.0f, 0.0f).RotateBy(f32(XORRandom(256)) * 360.0f / 255.0f), Vec2f_zero, color, true);
		if(p1 !is null)
		{
		    p1.collides = true;
		    p1.gravity = Vec2f_zero;
		    p1.bounce = 0;
		    p1.Z = 7;
		    p1.timeout = 10;
			p1.setRenderStyle(RenderStyle::light);
		}

		CParticle@ p2 = ParticlePixelUnlimited(pos + Vec2f(f32(XORRandom(256)) * 50.0f / 255.0f, 0.0f).RotateBy(f32(XORRandom(256)) * 360.0f / 255.0f), Vec2f(0.1f, 0.0f).RotateBy(f32(XORRandom(256)) * 360.0f / 255.0f), color, true);
		if(p2 !is null)
		{
		    p2.collides = true;
		    p2.gravity = Vec2f(0.0f, -0.1f);
		    p2.bounce = 0;
		    p2.Z = 7;
		    p2.timeout = 10;
			p2.setRenderStyle(RenderStyle::light);
		}
	}
}